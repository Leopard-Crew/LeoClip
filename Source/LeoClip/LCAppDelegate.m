#import "LCAppDelegate.h"

#define LC_MAX_HISTORY_ITEMS 20

@implementation LCAppDelegate

- (id)init
{
    self = [super init];
    if (self) {
        history = [[NSMutableArray alloc] init];
        lastChangeCount = -1;
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

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    lastChangeCount = [pasteboard changeCount];

    statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
    [statusItem setTitle:@"Clip"];
    [statusItem setHighlightMode:YES];
    [statusItem setTarget:self];
    [statusItem setAction:@selector(showMenu:)];
    [statusItem setEnabled:YES];

    statusMenu = [[NSMenu alloc] initWithTitle:@"LeoClip"];

    [self rebuildMenu];

    pollTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                target:self
                                              selector:@selector(checkPasteboard:)
                                              userInfo:nil
                                               repeats:YES];
}

- (NSString *)menuTitleForString:(NSString *)string
{
    NSString *title = [string stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    title = [title stringByReplacingOccurrencesOfString:@"\r" withString:@" "];

    if ([title length] > 60) {
        title = [[title substringToIndex:57] stringByAppendingString:@"..."];
    }

    if ([title length] == 0) {
        title = @"(empty text)";
    }

    return title;
}

- (void)rebuildMenu
{
    while ([statusMenu numberOfItems] > 0) {
        [statusMenu removeItemAtIndex:0];
    }

    NSMenuItem *titleItem = [[[NSMenuItem alloc] initWithTitle:@"LeoClip"
                                                        action:nil
                                                 keyEquivalent:@""] autorelease];
    [titleItem setEnabled:NO];
    [statusMenu addItem:titleItem];

    [statusMenu addItem:[NSMenuItem separatorItem]];

    if ([history count] == 0) {
        NSMenuItem *emptyItem = [[[NSMenuItem alloc] initWithTitle:@"No clips yet"
                                                            action:nil
                                                     keyEquivalent:@""] autorelease];
        [emptyItem setEnabled:NO];
        [statusMenu addItem:emptyItem];
    } else {
        NSUInteger index;
        for (index = 0; index < [history count]; index++) {
            NSString *clip = [history objectAtIndex:index];
            NSString *title = [self menuTitleForString:clip];

            NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:title
                                                           action:@selector(restoreClip:)
                                                    keyEquivalent:@""] autorelease];
            [item setTarget:self];
            [item setRepresentedObject:clip];
            [statusMenu addItem:item];
        }
    }

    [statusMenu addItem:[NSMenuItem separatorItem]];

    NSMenuItem *clearItem = [[[NSMenuItem alloc] initWithTitle:@"Clear History"
                                                        action:@selector(clearHistory:)
                                                 keyEquivalent:@""] autorelease];
    [clearItem setTarget:self];
    [clearItem setEnabled:([history count] > 0)];
    [statusMenu addItem:clearItem];

    [statusMenu addItem:[NSMenuItem separatorItem]];

    NSMenuItem *quitItem = [[[NSMenuItem alloc] initWithTitle:@"Quit LeoClip"
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

    NSString *string = [pasteboard stringForType:NSStringPboardType];
    if (!string || [string length] == 0) {
        return;
    }

    if ([history count] > 0 && [[history objectAtIndex:0] isEqualToString:string]) {
        return;
    }

    [history insertObject:[[string copy] autorelease] atIndex:0];

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

- (void)quit:(id)sender
{
    [NSApp terminate:self];
}

@end
