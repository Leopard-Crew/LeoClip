#import <Foundation/Foundation.h>
#import "LCClipboardHistory.h"

static void AssertTrue(BOOL condition, NSString *message)
{
    if (!condition) {
        NSLog(@"FAIL: %@", message);
        exit(1);
    }
}

int main(int argc, const char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    LCClipboardHistory *history = [[LCClipboardHistory alloc] initWithLimit:3];

    [history addString:@"Alpha"];
    [history addString:@"Beta"];
    [history addString:@"Alpha"];

    AssertTrue([history count] == 2, @"Duplicate clips should not increase history count.");
    AssertTrue([[history objectAtIndex:0] isEqualToString:@"Alpha"], @"Repeated clip should move to top.");
    AssertTrue([[history objectAtIndex:1] isEqualToString:@"Beta"], @"Previous clip should remain second.");

    [history addString:@"Gamma"];
    [history addString:@"Delta"];

    AssertTrue([history count] == 3, @"History should respect configured limit.");
    AssertTrue([[history objectAtIndex:0] isEqualToString:@"Delta"], @"Newest clip should be first.");
    AssertTrue([[history objectAtIndex:2] isEqualToString:@"Alpha"], @"Oldest retained clip should be Alpha.");

    [history removeAllObjects];

    AssertTrue([history count] == 0, @"Clear should remove all clips.");

    [history release];
    [pool drain];

    NSLog(@"LCClipboardHistory smoke test passed.");
    return 0;
}
