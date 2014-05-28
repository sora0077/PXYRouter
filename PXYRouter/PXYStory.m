//
//  PXYStory.m
//  PXYRouterDemo
//
//  Created by 林 達也 on 2014/05/09.
//  Copyright (c) 2014年 林 達也. All rights reserved.
//

#import "PXYStory.h"
#import "PXYStory+Internal.h"

#import "PXYRouter.h"
#import "PXYRouter+Internal.h"


@interface PXYFirstStory : PXYStory

- (id)initWithWindow:(UIWindow *)window;
@end

@interface PXYStory ()
@property (nonatomic, readwrite) BOOL waitUntilFinished;
@end

@implementation PXYStory
{
    id _patternComponents;
}

+ (PXYStory *)firstStoryWithWindow:(UIWindow *)window
{
    return [[PXYFirstStory alloc] initWithWindow:window];
}

+ (instancetype)storyWithPattern:(NSString *)pattern segue:(PXYStorySegueHandler)segue unwind:(PXYStorySegueHandler)unwind
{
    PXYStory *story = [[self alloc] initWithPattern:pattern segue:segue unwind:unwind];
    story.waitUntilFinished = YES;
    return story;
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

- (void)dealloc
{
    [[PXYRouterManager sharedManager] removeStory:self];
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


@implementation PXYFirstStory
{
    UIWindow *_window;
}

- (id)initWithWindow:(UIWindow *)window
{
    self = [super initWithPattern:nil segue:nil unwind:nil];
    if (self) {
        _window = window;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    id copy = [[[self class] allocWithZone:zone] initWithWindow:_window];
    return copy;
}

- (UIViewController *)destinationViewController
{
    return _window.rootViewController;
}


@end


