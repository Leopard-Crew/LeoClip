#import <Cocoa/Cocoa.h>

@interface LCPasteboardMonitor : NSObject
{
    NSPasteboard *pasteboard;
    NSInteger lastChangeCount;
}

- (id)initWithPasteboard:(NSPasteboard *)aPasteboard;

- (BOOL)consumeChangeIfNeeded;
- (NSString *)currentString;

- (void)writeStringAndSynchronize:(NSString *)string;

@end
