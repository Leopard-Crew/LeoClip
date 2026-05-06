#import <Cocoa/Cocoa.h>

@interface LCAppDelegate : NSObject
{
    NSStatusItem *statusItem;
    NSMenu *statusMenu;
    NSMutableArray *history;
    NSInteger lastChangeCount;
    NSTimer *pollTimer;
    BOOL capturePaused;
}

- (void)rebuildMenu;
- (void)showMenu:(id)sender;
- (void)checkPasteboard:(NSTimer *)timer;
- (void)restoreClip:(id)sender;
- (void)clearHistory:(id)sender;
- (void)togglePause:(id)sender;
- (void)quit:(id)sender;

@end
