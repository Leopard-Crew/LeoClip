#import "LCPasteboardMonitor.h"

@implementation LCPasteboardMonitor

- (id)initWithPasteboard:(NSPasteboard *)aPasteboard
{
    self = [super init];

    if (self) {
        pasteboard = [aPasteboard retain];

        if (!pasteboard) {
            pasteboard = [[NSPasteboard generalPasteboard] retain];
        }

        lastChangeCount = [pasteboard changeCount];
    }

    return self;
}

- (void)dealloc
{
    [pasteboard release];

    [super dealloc];
}

- (BOOL)consumeChangeIfNeeded
{
    NSInteger changeCount = [pasteboard changeCount];

    if (changeCount == lastChangeCount) {
        return NO;
    }

    lastChangeCount = changeCount;

    return YES;
}

- (NSString *)currentString
{
    return [pasteboard stringForType:NSStringPboardType];
}

- (void)writeStringAndSynchronize:(NSString *)string
{
    if (!string) {
        return;
    }

    [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    [pasteboard setString:string forType:NSStringPboardType];

    lastChangeCount = [pasteboard changeCount];
}

@end
