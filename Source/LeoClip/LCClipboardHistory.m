#import "LCClipboardHistory.h"

@implementation LCClipboardHistory

- (id)initWithLimit:(NSUInteger)aLimit
{
    self = [super init];

    if (self) {
        items = [[NSMutableArray alloc] init];
        limit = aLimit;
    }

    return self;
}

- (void)dealloc
{
    [items release];

    [super dealloc];
}

- (NSUInteger)count
{
    return [items count];
}

- (NSString *)objectAtIndex:(NSUInteger)index
{
    return [items objectAtIndex:index];
}

- (void)addString:(NSString *)string
{
    if (!string) {
        return;
    }

    NSString *clip = [string copy];

    [items removeObject:clip];
    [items insertObject:clip atIndex:0];

    [clip release];

    while ([items count] > limit) {
        [items removeLastObject];
    }
}

- (void)removeAllObjects
{
    [items removeAllObjects];
}

@end
