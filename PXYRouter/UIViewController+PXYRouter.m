//
//  UIViewController+PXYRouter.m
//  PXYRouterDemo
//
//  Created by 林 達也 on 2014/05/16.
//  Copyright (c) 2014年 林 達也. All rights reserved.
//

#import "UIViewController+PXYRouter.h"
#import "PXYStory.h"
#import <objc/runtime.h>

#import <Aspects/Aspects.h>
#import "PXYRouter+Internal.h"

@implementation UIViewController (PXYRouter)

+ (void)load
{
    [self aspect_hookSelector:NSSelectorFromString(@"dealloc")
                  withOptions:AspectPositionBefore
                   usingBlock:^(id<AspectInfo> aspectInfo) {
                       UIViewController *viewController = [aspectInfo instance];
                       if (viewController.pxy_story) {
                           [[PXYRouterManager sharedManager] removeStory:viewController.pxy_story];
                       }
                   }
                        error:NULL];
}

- (void)setPxy_story:(PXYStory *)pxy_story
{
    objc_setAssociatedObject(self, @selector(pxy_story), pxy_story, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (PXYStory *)pxy_story
{
    return objc_getAssociatedObject(self, @selector(pxy_story));
}

@end
