//
//  PXYRouter.m
//  PXYRouterDemo
//
//  Created by 林 達也 on 2014/05/09.
//  Copyright (c) 2014年 林 達也. All rights reserved.
//

#import "PXYRouter.h"
#import "PXYRouter+Internal.h"
#import "PXYStory.h"
#import "PXYStory+Internal.h"
#import "UIViewController+PXYRouter.h"

#import <Aspects/Aspects.h>


typedef void (^PXYSegueCompletion)(PXYStory *stack);
typedef BOOL (^PXYSegueHandler)(PXYStory *top, PXYStory *second, PXYSegueCompletion completion);

static const NSString *const PXYStoryAnyPattern = @"__any__";


@interface PXYRouterManager ()

@property (nonatomic) NSMutableDictionary *routers;
@property (nonatomic) NSMutableArray *stacks;
@property (nonatomic) NSMutableArray *waitings;
@property (nonatomic) BOOL segueing;
@end

@interface PXYRouter ()
@property (nonatomic) NSString *scheme;
@property (nonatomic) NSMutableDictionary *stories;
@property (nonatomic) NSMutableArray *queue;
@property (nonatomic) PXYStory *unresolvedStory;
@property (nonatomic, copy) BOOL (^resolveURLHandler)(NSURL *);

@end

static void dispatch_async_main_queue(void (^block)(void))
{
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

@implementation PXYRouterManager

+ (instancetype)sharedManager
{
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (id)init
{
    self = [super init];
    if (self) {
        _routers = @{}.mutableCopy;
        _stacks = @[].mutableCopy;
        _waitings = @[].mutableCopy;
    }
    return self;
}

- (PXYRouter *)routerWithScheme:(NSString *)scheme
{
    return self.routers[scheme];
}

- (void)addRouter:(PXYRouter *)router forScheme:(NSString *)scheme
{
    self.routers[scheme] = router;
}

- (void)addQueue:(PXYSegueHandler)next
{
    next = [next copy];
    [self.waitings addObject:next];
    if (!self.segueing) {
        PXYSegueHandler next = self.waitings.firstObject;
        [self.waitings removeObjectAtIndex:0];
        [self performHandler:next];
    }
}

- (void)performHandler:(PXYSegueHandler)handler
{
    PXYStory *top = self.stacks.lastObject;
    PXYStory *second = self.stacks.count > 1 ? [self.stacks objectAtIndex:self.stacks.count - 2] : nil;
    self.segueing = YES;
    handler(top, second, ^(PXYStory *story){
        if (story) {
            [self.stacks addObject:story];
        } else {
            [self.stacks removeObject:top];
        }
        if (self.waitings.count) {
            PXYSegueHandler next = self.waitings.firstObject;
            [self.waitings removeObjectAtIndex:0];
            dispatch_async_main_queue(^{
                self.segueing = NO;
                [self performHandler:next];
            });
        } else {
            self.segueing = NO;
        }
    });
}

- (void)addStory:(PXYStory *)story
{
    [self.stacks addObject:story];
}

- (BOOL)removeStory:(PXYStory *)story
{
    if ([self.stacks containsObject:story]) {
        [self.stacks removeObject:story];
        return YES;
    }
    return NO;
}

@end

#pragma mark - PXYRouter

@implementation PXYRouter

+ (instancetype)defaultScheme
{
    static PXYRouter *router;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *scheme = [NSBundle mainBundle].infoDictionary[@"CFBundleURLTypes"][0][@"CFBundleURLSchemes"][0];
        router = [self scheme:scheme];
    });
    return router;
}

+ (instancetype)scheme:(NSString *)scheme
{
    PXYRouter *router = [[PXYRouterManager sharedManager] routerWithScheme:scheme];
    if (!router) {
        router = [[self alloc] initWithScheme:scheme];
        [[PXYRouterManager sharedManager] addRouter:router forScheme:scheme];
    }
    return router;
}

- (id)initWithScheme:(NSString *)scheme
{
    self = [super init];
    if (self) {
        _scheme = [scheme copy];
        _stories = @{}.mutableCopy;
    }
    return self;
}

+ (void)routingOnWindow:(UIWindow *)window
{
    [[PXYRouterManager sharedManager] addStory:[PXYStory firstStoryWithWindow:window]];
    NSParameterAssert(window.rootViewController);
}

+ (BOOL)canOpenURL:(NSURL *)url
{
    PXYRouter *router = [[PXYRouterManager sharedManager] routerWithScheme:url.scheme];

    return [router canOpenURL:url];
}

+ (void)openURL:(NSURL *)url
{
    [self openURL:url animated:YES];
}

+ (void)openURL:(NSURL *)url animated:(BOOL)animated
{
    PXYRouter *router = [[PXYRouterManager sharedManager] routerWithScheme:url.scheme];

    [router openURL:url animated:animated];
}

+ (void)pop
{
    [self pop:YES];
}

+ (void)pop:(BOOL)animated
{
    [[PXYRouterManager sharedManager] addQueue:^BOOL(PXYStory *top, PXYStory *second, PXYSegueCompletion completion) {
        UIViewController *source = top.destinationViewController;
        UIViewController *destination = second.destinationViewController;
        [source aspect_hookSelector:@selector(viewDidDisappear:)
                        withOptions:AspectPositionAfter | AspectOptionAutomaticRemoval
                         usingBlock:^(id<AspectInfo> aspectInfo, BOOL animated) {
                             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                 if (completion) {
                                     completion(nil);
                                 }
                             });
                         }
                              error:NULL];

        dispatch_async_main_queue(^{
            top.unwind(source, destination, animated);
        });
        return YES;
    }];
}

- (BOOL)canOpenURL:(NSURL *)url
{
    PXYStory *story = [self storyForURL:url];
    return story != nil;
}

- (void)openURL:(NSURL *)url
{
    [self openURL:url animated:YES];
}

- (void)openURL:(NSURL *)url animated:(BOOL)animated
{
    PXYStory *story = [self storyForURL:url];
    NSDictionary *params = [story parametersForURL:url];

    if (params) {
        PXYSegueHandler handler = [self prepareSegueWithStory:story url:url parameters:params animated:animated];
        if (story.waitUntilFinished) {
            [[PXYRouterManager sharedManager] addQueue:handler];
        } else {
            handler(nil, nil, nil);
        }
    }
}

- (void)addStory:(PXYStory *)story handler:(UIViewController *(^)(NSURL *, NSDictionary *))handler
{
    if (story.handler == nil && handler) {
        story.handler = handler;
    }
    NSArray *patternComponents = story.patternComponents;
    NSMutableDictionary *parent = self.stories[@(patternComponents.count)];

    if (!parent) {
        parent = @{}.mutableCopy;
        self.stories[@(patternComponents.count)] = parent;
    }
    for (id obj in patternComponents) {
        const NSString *pattern = [obj hasPrefix:@":"] ? PXYStoryAnyPattern : obj;

        NSParameterAssert([parent isKindOfClass:[NSDictionary class]]);
        NSMutableDictionary *tree = parent[pattern];
        if (obj == patternComponents.lastObject) {
            parent[pattern] = story;
        } else if (!tree) {
            tree = @{}.mutableCopy;
            parent[pattern] = tree;
        }
        parent = tree;
    }
}

- (PXYSegueHandler)prepareSegueWithStory:(PXYStory *)story url:(NSURL *)url parameters:(NSDictionary *)params animated:(BOOL)animated
{
    return ^BOOL(PXYStory *top, PXYStory *second, PXYSegueCompletion completion) {
        return [self performSegueWithStory:story
                                        on:top
                                       url:url
                                parameters:params
                                  animated:animated
                                completion:completion];
    };
}

- (BOOL)performSegueWithStory:(PXYStory *)story on:(PXYStory *)on url:(NSURL *)url parameters:(NSDictionary *)params animated:(BOOL)animated completion:(PXYSegueCompletion)completion
{
    UIViewController *destination = story.handler(url, params);
    if (destination) {
        NSParameterAssert(story.segue);
        NSParameterAssert(story.unwind);

        PXYStory *stack = [story copy];
        stack.url = url;
        stack.destinationViewController = destination;
        stack.router = self;

        destination.pxy_story = stack;
        [destination aspect_hookSelector:@selector(viewDidAppear:)
                             withOptions:AspectPositionAfter | AspectOptionAutomaticRemoval
                              usingBlock:^(id<AspectInfo> aspectInfo, BOOL animated) {
                                  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

                                      if (completion) {
                                          completion(stack);
                                      }
                                  });
                              }
                                   error:NULL];

        dispatch_async_main_queue(^{
            stack.segue(on.destinationViewController, destination, animated);
        });
        return YES;
    }
    return NO;
}


- (PXYStory *)storyForURL:(NSURL *)url
{
    NSArray *patternComponents = [[url.host stringByAppendingPathComponent:url.path] componentsSeparatedByString:@"/"];
    NSDictionary *parent = self.stories[@(patternComponents.count)];
    if (parent == nil) {
        return nil;
    }

    for (NSString *pattern in patternComponents) {
        NSParameterAssert([parent isKindOfClass:[NSDictionary class]]);
        id tree = [parent objectForKey:pattern];
        if (tree == nil) {
            tree = [parent objectForKey:PXYStoryAnyPattern];
            if (tree == nil) {
                return tree;
            }
        }
        if (pattern == patternComponents.lastObject) {
            return tree;
        } else if ([tree isKindOfClass:[PXYStory class]]) {
            return nil;
        }

        parent = tree;
    }
    return nil;
}

@end
