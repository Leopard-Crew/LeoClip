#import <Cocoa/Cocoa.h>

@interface LCClipboardHistory : NSObject
{
    NSMutableArray *items;
    NSUInteger limit;
}

- (id)initWithLimit:(NSUInteger)aLimit;

- (NSUInteger)count;
- (NSString *)objectAtIndex:(NSUInteger)index;

- (void)addString:(NSString *)string;
- (void)removeAllObjects;

@end
