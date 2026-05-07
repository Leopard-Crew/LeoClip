#import <Cocoa/Cocoa.h>

@class LCClipboardHistory;

@interface LCAppDelegate : NSObject
{
    NSStatusItem *statusItem;
    NSMenu *statusMenu;
    LCClipboardHistory *history;
    NSInteger lastChangeCount;
    NSTimer *pollTimer;
    BOOL capturePaused;
}

- (void)rebuildMenu;
- (void)updateStatusItemTitle;
- (void)checkPasteboard:(NSTimer *)timer;
- (void)restoreClip:(id)sender;
- (void)clearHistory:(id)sender;
- (void)togglePause:(id)sender;
- (void)quit:(id)sender;

@end
