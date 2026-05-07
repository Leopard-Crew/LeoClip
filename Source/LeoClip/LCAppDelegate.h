#import <Cocoa/Cocoa.h>

@class LCClipboardHistory;
@class LCPasteboardMonitor;

@interface LCAppDelegate : NSObject
{
    NSStatusItem *statusItem;
    NSMenu *statusMenu;
    LCClipboardHistory *history;
    LCPasteboardMonitor *pasteboardMonitor;
    NSTimer *pollTimer;
    BOOL capturePaused;
}

- (void)rebuildMenu;
- (void)updateStatusItemTitle;
- (void)checkPasteboard:(NSTimer *)timer;
- (void)restoreClip:(id)sender;
- (void)clearHistory:(id)sender;
- (void)showAbout:(id)sender;
- (void)togglePause:(id)sender;
- (void)quit:(id)sender;

@end
