#import <Cocoa/Cocoa.h>
#import "LCAppDelegate.h"

int main(int argc, char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSApplication *application = [NSApplication sharedApplication];
    LCAppDelegate *delegate = [[LCAppDelegate alloc] init];

    [application setDelegate:delegate];
    [application run];

    [delegate release];
    [pool release];

    return 0;
}
