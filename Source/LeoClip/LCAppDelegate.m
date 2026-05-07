#import "LCAppDelegate.h"
#import "LCClipboardHistory.h"
#import "LCPasteboardMonitor.h"

static const NSUInteger LCMaxHistoryItems = 20;
static const NSUInteger LCMenuTitleLimit = 56;

static const NSTimeInterval LCPasteboardPollInterval = 0.5;

static const CGFloat LCStatusGlyphFontSize = 21.0;
static const CGFloat LCStatusItemLength = 28.0;

static const unichar LCStatusGlyphActive = 0x29C9;
static const unichar LCStatusGlyphPaused = 0x29C8;

@interface LCAppDelegate (PrivateMenu)

- (NSMenuItem *)menuItemWithTitle:(NSString *)title
                           action:(SEL)action
                    keyEquivalent:(NSString *)keyEquivalent;

- (void)addAboutItemToMenu;
- (void)addHistoryItemsToMenu;
- (void)addControlItemsToMenu;

@end

@implementation LCAppDelegate

- (id)init
{
    self = [super init];
    if (self) {
        history = [[LCClipboardHistory alloc] initWithLimit:LCMaxHistoryItems];
        pasteboardMonitor = [[LCPasteboardMonitor alloc] initWithPasteboard:[NSPasteboard generalPasteboard]];
        capturePaused = NO;
    }
    return self;
}

- (void)dealloc
{
    [pollTimer invalidate];
    [history release];
    [pasteboardMonitor release];
    [statusMenu release];

    if (statusItem) {
        [[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
        [statusItem release];
    }

    [super dealloc];
}

- (void)updateStatusItemTitle
{
    unichar statusGlyph = capturePaused ? LCStatusGlyphPaused : LCStatusGlyphActive;
    NSString *statusTitle = [NSString stringWithCharacters:&statusGlyph length:1];

    NSFont *statusFont = [NSFont systemFontOfSize:LCStatusGlyphFontSize];
    NSDictionary *statusAttributes = [NSDictionary dictionaryWithObject:statusFont
                                                                 forKey:NSFontAttributeName];
    NSAttributedString *attributedStatusTitle = [[[NSAttributedString alloc] initWithString:statusTitle
                                                                                 attributes:statusAttributes] autorelease];

    [statusItem setAttributedTitle:attributedStatusTitle];
    [statusItem setLength:LCStatusItemLength];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
    [self updateStatusItemTitle];

    [statusItem setHighlightMode:YES];
    [statusItem setToolTip:@"LeoClip"];

    statusMenu = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"LeoClip", nil)];

    [self rebuildMenu];
    [statusItem setMenu:statusMenu];

    /*
     NSPasteboard has no simple Leopard-era notification hook for general
     clipboard changes. Polling changeCount is intentional here: small,
     deterministic, and sufficient for a lightweight menu bar tool.
     */
    pollTimer = [NSTimer scheduledTimerWithTimeInterval:LCPasteboardPollInterval
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

    if ([title length] > LCMenuTitleLimit) {
        title = [[title substringToIndex:(LCMenuTitleLimit - 3)] stringByAppendingString:@"..."];
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

- (NSMenuItem *)menuItemWithTitle:(NSString *)title
                           action:(SEL)action
                    keyEquivalent:(NSString *)keyEquivalent
{
    NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:title
                                                   action:action
                                            keyEquivalent:keyEquivalent] autorelease];

    [item setTarget:self];

    return item;
}

- (void)addAboutItemToMenu
{
    NSMenuItem *aboutItem = [self menuItemWithTitle:NSLocalizedString(@"About LeoClip", nil)
                                            action:@selector(showAbout:)
                                     keyEquivalent:@""];

    [statusMenu addItem:aboutItem];
    [statusMenu addItem:[NSMenuItem separatorItem]];
}

- (void)addHistoryItemsToMenu
{
    if ([history count] == 0) {
        NSMenuItem *emptyItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"No Clips", nil)
                                                            action:nil
                                                     keyEquivalent:@""] autorelease];

        [emptyItem setEnabled:NO];
        [statusMenu addItem:emptyItem];

        return;
    }

    NSUInteger index;

    for (index = 0; index < [history count]; index++) {
        NSString *clip = [history objectAtIndex:index];
        NSString *itemTitle = [self menuTitleForString:clip index:index];
        NSString *keyEquivalent = @"";

        if (index < 9) {
            keyEquivalent = [NSString stringWithFormat:@"%lu", (unsigned long)(index + 1)];
        }

        NSMenuItem *item = [self menuItemWithTitle:itemTitle
                                           action:@selector(restoreClip:)
                                    keyEquivalent:keyEquivalent];

        if ([keyEquivalent length] > 0) {
            [item setKeyEquivalentModifierMask:NSCommandKeyMask];
        }

        [item setRepresentedObject:clip];
        [statusMenu addItem:item];
    }
}

- (void)addControlItemsToMenu
{
    NSString *pauseTitle = capturePaused
        ? NSLocalizedString(@"Resume Clipboard History", nil)
        : NSLocalizedString(@"Pause Clipboard History", nil);

    NSMenuItem *pauseItem = [self menuItemWithTitle:pauseTitle
                                            action:@selector(togglePause:)
                                     keyEquivalent:@""];

    NSMenuItem *clearItem = [self menuItemWithTitle:NSLocalizedString(@"Clear History", nil)
                                            action:@selector(clearHistory:)
                                     keyEquivalent:@""];

    NSMenuItem *quitItem = [self menuItemWithTitle:NSLocalizedString(@"Quit LeoClip", nil)
                                           action:@selector(quit:)
                                    keyEquivalent:@"q"];

    [clearItem setEnabled:([history count] > 0)];

    [statusMenu addItem:[NSMenuItem separatorItem]];
    [statusMenu addItem:pauseItem];
    [statusMenu addItem:clearItem];

    [statusMenu addItem:[NSMenuItem separatorItem]];
    [statusMenu addItem:quitItem];
}

- (void)rebuildMenu
{
    [self removeAllMenuItems];

    [self addAboutItemToMenu];
    [self addHistoryItemsToMenu];
    [self addControlItemsToMenu];
}


- (void)checkPasteboard:(NSTimer *)timer
{
    if (![pasteboardMonitor consumeChangeIfNeeded]) {
        return;
    }

    if (capturePaused) {
        return;
    }

    NSString *string = [pasteboardMonitor currentString];
    if (![self stringHasUsefulContent:string]) {
        return;
    }

    [history addString:string];

    [self rebuildMenu];
}

- (void)restoreClip:(id)sender
{
    NSString *clip = [sender representedObject];
    if (!clip) {
        return;
    }

    [pasteboardMonitor writeStringAndSynchronize:clip];
}

- (void)clearHistory:(id)sender
{
    [NSApp activateIgnoringOtherApps:YES];

    NSAlert *alert = [[[NSAlert alloc] init] autorelease];

    [alert setAlertStyle:NSWarningAlertStyle];
    [alert setMessageText:NSLocalizedString(@"Clear Clipboard History?", nil)];
    [alert setInformativeText:NSLocalizedString(@"This removes all stored clips from LeoClip. The current clipboard contents are not changed.", nil)];

    [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Clear History", nil)];

    if ([alert runModal] != NSAlertSecondButtonReturn) {
        return;
    }

    [history removeAllObjects];
    [self rebuildMenu];
}

- (void)showAbout:(id)sender
{
    [NSApp activateIgnoringOtherApps:YES];
    [NSApp orderFrontStandardAboutPanel:sender];
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
