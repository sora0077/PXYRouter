//
//  PXYStory.m
//  PXYRouterDemo
//
//  Created by 林 達也 on 2014/05/09.
//  Copyright (c) 2014年 林 達也. All rights reserved.
//

#import "PXYStory.h"
#import "PXYStory+Internal.h"

@implementation PXYStory
{
    id _patternComponents;
}

+ (instancetype)storyWithPattern:(NSString *)pattern segue:(PXYStorySegueHandler)segue unwind:(PXYStorySegueHandler)unwind
{
    return [[self alloc] initWithPattern:pattern segue:segue unwind:unwind];
}

+ (instancetype)apiWithPattern:(NSString *)pattern
{
    return [[self alloc] initWithPattern:pattern segue:nil unwind:nil];
}

- (id)initWithPattern:(NSString *)pattern segue:(PXYStorySegueHandler)segue unwind:(PXYStorySegueHandler)unwind
{
    self = [super init];
    if (self) {
        if ([pattern hasPrefix:@"/"]) pattern = [pattern substringFromIndex:1];
        if ([pattern hasSuffix:@"/"]) pattern = [pattern substringToIndex:pattern.length-1];
        _pattern = [pattern copy];
        _segue = [segue copy];
        _unwind = [unwind copy];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    id copy = [[[self class] allocWithZone:zone] initWithPattern:_pattern
                                                           segue:_segue
                                                          unwind:_unwind];
    return copy;
}

- (NSArray *)patternComponents
{
    if (!_patternComponents) {
        _patternComponents = [self.pattern componentsSeparatedByString:@"/"];
    }
    return _patternComponents;
}

- (NSDictionary *)parametersForURL:(NSURL *)url
{
    NSArray *urlComponents = [[url.host stringByAppendingPathComponent:url.path] componentsSeparatedByString:@"/"];
    if (urlComponents.count != self.patternComponents.count) return nil;

    NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:urlComponents.count];
    for (int i = 0; i < urlComponents.count; i++) {
        id obj = urlComponents[i];
        NSString *key = self.patternComponents[i];
        if ([key hasPrefix:@":"]) {
            [parameter setObject:obj forKey:[key substringFromIndex:1]];
        } else if (![key isEqualToString:obj]) {
            return nil;
        }
    }
    return parameter;
}

@end
