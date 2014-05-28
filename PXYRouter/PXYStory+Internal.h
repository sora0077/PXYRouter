//
//  PXYStory+Internal.h
//  PXYRouterDemo
//
//  Created by 林 達也 on 2014/05/09.
//  Copyright (c) 2014年 林 達也. All rights reserved.
//

#import "PXYStory.h"

@class PXYRouter;
@interface PXYStory () <NSCopying, UINavigationControllerDelegate, UITabBarControllerDelegate>

+ (PXYStory *)firstStoryWithWindow:(UIWindow *)window;

@property (nonatomic, copy) UIViewController *(^handler)(NSURL *url, NSDictionary *params);
@property (nonatomic, copy) PXYStorySegueHandler segue;
@property (nonatomic, copy) PXYStorySegueHandler unwind;

@property (nonatomic, copy) NSURL *url;
@property (nonatomic, weak) UIViewController *destinationViewController;
//@property (nonatomic, weak) UIViewController *sourceViewController;
@property (nonatomic, readonly) NSArray *patternComponents;
@property (nonatomic, weak) PXYRouter *router;
- (NSDictionary *)parametersForURL:(NSURL *)url;
@end
