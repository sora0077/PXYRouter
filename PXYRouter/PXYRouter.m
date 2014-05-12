//
//  PXYRouter.m
//  PXYRouterDemo
//
//  Created by 林 達也 on 2014/05/09.
//  Copyright (c) 2014年 林 達也. All rights reserved.
//

#import "PXYRouter.h"
#import "PXYStory.h"
#import "PXYStory+Internal.h"

static const NSString *const PXYStoryAnyPattern = @"__any__";
static id _window;
static void (^_popToRootBlock)(BOOL);

@interface PXYRouter ()
@property (nonatomic) NSString *scheme;
@property (nonatomic) NSMutableDictionary *stories;
@property (nonatomic) PXYStory *unresolvedStory;
@property (nonatomic, copy) BOOL (^resolveURLHandler)(NSURL *);
@end

@implementation PXYRouter

+ (NSMutableDictionary *)routers
{
    static NSMutableDictionary *routers;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        routers = @{}.mutableCopy;
    });
    return routers;
}

+ (NSMutableArray *)stacks
{
    static NSMutableArray *stacks;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        stacks = @[].mutableCopy;
    });
    return stacks;
}

+ (void)setPopToRootBlock:(void (^)(BOOL))block
{
    _popToRootBlock = [block copy];
}

+ (void (^)(BOOL))popToRootBlock
{
    return _popToRootBlock;
}

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
    PXYRouter *router = [self routers][scheme];
    if (!router) {
        router = [[self alloc] initWithScheme:scheme];
        [self routers][scheme] = router;
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
    _window = window;
    NSParameterAssert(window.rootViewController);

    __weak UIViewController *selectedController;
    if ([window.rootViewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabController = (id)window.rootViewController;
        selectedController = tabController.selectedViewController;
    }
    [self setPopToRootBlock:^(BOOL animated) {
        UIViewController *topViewController = [self window].rootViewController;
        if ([topViewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *navController = (id)topViewController;
            [navController popToRootViewControllerAnimated:animated];
        } else if ([topViewController isKindOfClass:[UITabBarController class]]) {
            UITabBarController *tabController = (id)topViewController;
            if ([tabController.viewControllers containsObject:selectedController]) {
                [tabController setSelectedViewController:selectedController];
            }
        }
    }];
}

+ (UIWindow *)window
{
    return _window;
}

+ (BOOL)canOpenURL:(NSURL *)url
{
    PXYRouter *router = [[self class] routers][url.scheme];

    return [router canOpenURL:url];
}

+ (void)openURL:(NSURL *)url
{
    [self openURL:url animated:YES];
}

+ (void)openURL:(NSURL *)url animated:(BOOL)animated
{
    PXYRouter *router = [[self class] routers][url.scheme];

    [router openURL:url animated:animated];
}

+ (void)pop
{
    [self pop:YES];
}

+ (void)pop:(BOOL)animated
{
    PXYStory *story = [self topStory];
    if (story) {
        UIViewController *source = story.sourceViewController;
        UIViewController *destination = story.destinationViewController;

        dispatch_async(dispatch_get_main_queue(), ^{
            story.unwind(source, destination, animated);
        });

        [[self stacks] removeLastObject];
    }
}

+ (void)popToRoot:(BOOL)animated
{
    [[self stacks] removeAllObjects];
    UIViewController *topViewController = [self stackedController];

    if (topViewController.presentedViewController) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [topViewController dismissViewControllerAnimated:animated completion:nil];
        });
        animated = NO;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        void (^popToRootBlock)(BOOL) = [self popToRootBlock];
        popToRootBlock(animated);
    });
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
        [self performSegueWithStory:story url:url parameters:params animated:animated];
        return;
    }

    if (self.unresolvedStory) {
        [self performSegueWithStory:self.unresolvedStory url:url parameters:params animated:YES];
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

+ (PXYStory *)topStory
{
    if ([self stacks].count) {
        PXYStory *story = [self stacks].lastObject;
        UIViewController *source = story.sourceViewController;
        UIViewController *destination = story.destinationViewController;
        BOOL isVisible = destination.isViewLoaded && destination.view.window;
        if (source && destination && isVisible) {
            return story;
        } else {
            [[self stacks] removeLastObject];
            return [self topStory];
        }
    }
    return nil;
}

+ (UIViewController *)stackedController
{
    PXYStory *story = [self topStory];
    if (story) {
        return story.destinationViewController;
    }
    return [self window].rootViewController;
}

- (BOOL)performSegueWithStory:(PXYStory *)story url:(NSURL *)url parameters:(NSDictionary *)params animated:(BOOL)animated
{
    UIViewController *destination = story.handler(url, params);
    if (destination) {
        NSParameterAssert(story.segue);
        NSParameterAssert(story.unwind);
        UIViewController *source = [[self class] stackedController];

        PXYStory *stack = [story copy];
        stack.url = url;
        stack.destinationViewController = destination;
        stack.sourceViewController = source;

        dispatch_async(dispatch_get_main_queue(), ^{
            story.segue(source, destination, animated);
        });

        [[[self class] stacks] addObject:stack];
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
