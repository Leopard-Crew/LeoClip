#import "LCAppDelegate.h"

#define LC_MAX_HISTORY_ITEMS 20
#define LC_MENU_TITLE_LIMIT 56

@implementation LCAppDelegate

- (id)init
{
    self = [super init];
    if (self) {
        history = [[NSMutableArray alloc] init];
        lastChangeCount = -1;
        capturePaused = NO;
    }
    return self;
}

- (void)dealloc
{
    [pollTimer invalidate];
    [history release];
    [statusMenu release];

    if (statusItem) {
        [[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
        [statusItem release];
    }

    [super dealloc];
}

- (void)updateStatusItemTitle
{
    unichar statusGlyph = capturePaused ? 0x29C8 : 0x29C9;
    NSString *statusTitle = [NSString stringWithCharacters:&statusGlyph length:1];

    NSFont *statusFont = [NSFont systemFontOfSize:21.0];
    NSDictionary *statusAttributes = [NSDictionary dictionaryWithObject:statusFont
                                                                 forKey:NSFontAttributeName];
    NSAttributedString *attributedStatusTitle = [[[NSAttributedString alloc] initWithString:statusTitle
                                                                                 attributes:statusAttributes] autorelease];

    [statusItem setAttributedTitle:attributedStatusTitle];
    [statusItem setLength:28.0];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    lastChangeCount = [pasteboard changeCount];

    statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
    [self updateStatusItemTitle];

    [statusItem setHighlightMode:YES];
    [statusItem setTarget:self];
    [statusItem setAction:@selector(showMenu:)];
    [statusItem setEnabled:YES];

    statusMenu = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"LeoClip", nil)];

    [self rebuildMenu];

    pollTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                target:self
                                              selector:@selector(checkPasteboard:)
                                              userInfo:nil
                                               repeats:YES];
}

- (BOOL)stringHasUsefulContent:(NSString *)string
{
    if (!string) {
        return NO;
    }

    NSString *trimmed = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return ([trimmed length] > 0);
}

- (NSString *)menuTitleForString:(NSString *)string index:(NSUInteger)index
{
    NSString *title = [string stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    title = [title stringByReplacingOccurrencesOfString:@"\r" withString:@" "];

    if ([title length] > LC_MENU_TITLE_LIMIT) {
        title = [[title substringToIndex:(LC_MENU_TITLE_LIMIT - 3)] stringByAppendingString:@"..."];
    }

    if ([title length] == 0) {
        title = NSLocalizedString(@"(empty text)", nil);
    }

    return [NSString stringWithFormat:@"%lu. %@", (unsigned long)(index + 1), title];
}

- (void)removeAllMenuItems
{
    while ([statusMenu numberOfItems] > 0) {
        [statusMenu removeItemAtIndex:0];
    }
}

- (void)rebuildMenu
{
    [self removeAllMenuItems];

    NSString *title = capturePaused ? NSLocalizedString(@"LeoClip - Paused", nil) : NSLocalizedString(@"LeoClip", nil);
    NSMenuItem *titleItem = [[[NSMenuItem alloc] initWithTitle:title
                                                        action:nil
                                                 keyEquivalent:@""] autorelease];
    [titleItem setEnabled:NO];
    [statusMenu addItem:titleItem];

    [statusMenu addItem:[NSMenuItem separatorItem]];

    if ([history count] == 0) {
        NSMenuItem *emptyItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"No Clips", nil)
                                                            action:nil
                                                     keyEquivalent:@""] autorelease];
        [emptyItem setEnabled:NO];
        [statusMenu addItem:emptyItem];
    } else {
        NSUInteger index;
        for (index = 0; index < [history count]; index++) {
            NSString *clip = [history objectAtIndex:index];
            NSString *itemTitle = [self menuTitleForString:clip index:index];

            NSString *keyEquivalent = @"";
            if (index < 9) {
                keyEquivalent = [NSString stringWithFormat:@"%lu", (unsigned long)(index + 1)];
            }

            NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:itemTitle
                                                           action:@selector(restoreClip:)
                                                    keyEquivalent:keyEquivalent] autorelease];
            [item setKeyEquivalentModifierMask:NSCommandKeyMask];
            [item setTarget:self];
            [item setRepresentedObject:clip];
            [statusMenu addItem:item];
        }
    }

    [statusMenu addItem:[NSMenuItem separatorItem]];

    NSString *pauseTitle = capturePaused ? NSLocalizedString(@"Resume Clipboard History", nil) : NSLocalizedString(@"Pause Clipboard History", nil);
    NSMenuItem *pauseItem = [[[NSMenuItem alloc] initWithTitle:pauseTitle
                                                        action:@selector(togglePause:)
                                                 keyEquivalent:@""] autorelease];
    [pauseItem setTarget:self];
    [statusMenu addItem:pauseItem];

    NSMenuItem *clearItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Clear History", nil)
                                                        action:@selector(clearHistory:)
                                                 keyEquivalent:@""] autorelease];
    [clearItem setTarget:self];
    [clearItem setEnabled:([history count] > 0)];
    [statusMenu addItem:clearItem];

    [statusMenu addItem:[NSMenuItem separatorItem]];

    NSMenuItem *quitItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Quit LeoClip", nil)
                                                       action:@selector(quit:)
                                                keyEquivalent:@"q"] autorelease];
    [quitItem setTarget:self];
    [statusMenu addItem:quitItem];
}

- (void)showMenu:(id)sender
{
    [statusItem popUpStatusItemMenu:statusMenu];
}

- (void)checkPasteboard:(NSTimer *)timer
{
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSInteger changeCount = [pasteboard changeCount];

    if (changeCount == lastChangeCount) {
        return;
    }

    lastChangeCount = changeCount;

    if (capturePaused) {
        return;
    }

    NSString *string = [pasteboard stringForType:NSStringPboardType];
    if (![self stringHasUsefulContent:string]) {
        return;
    }

    NSString *clip = [string copy];

    [history removeObject:clip];
    [history insertObject:clip atIndex:0];
    [clip release];

    while ([history count] > LC_MAX_HISTORY_ITEMS) {
        [history removeLastObject];
    }

    [self rebuildMenu];
}

- (void)restoreClip:(id)sender
{
    NSString *clip = [sender representedObject];
    if (!clip) {
        return;
    }

    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    [pasteboard setString:clip forType:NSStringPboardType];

    lastChangeCount = [pasteboard changeCount];
}

- (void)clearHistory:(id)sender
{
    [history removeAllObjects];
    [self rebuildMenu];
}

- (void)togglePause:(id)sender
{
    capturePaused = !capturePaused;
    [self updateStatusItemTitle];
    [self rebuildMenu];
}

- (void)quit:(id)sender
{
    [NSApp terminate:self];
}

@end
