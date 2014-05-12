//
//  PXYRouter.h
//  PXYRouterDemo
//
//  Created by 林 達也 on 2014/05/09.
//  Copyright (c) 2014年 林 達也. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PXYStory.h"

@interface PXYRouter : NSObject

+ (instancetype)defaultScheme;
+ (instancetype)scheme:(NSString *)scheme;

+ (void)routingOnWindow:(UIWindow *)window;


+ (BOOL)canOpenURL:(NSURL *)url;
+ (void)openURL:(NSURL *)url;
+ (void)openURL:(NSURL *)url animated:(BOOL)animated;
+ (void)pop;
+ (void)pop:(BOOL)animated;
+ (void)popToRoot:(BOOL)animated;


- (void)openURL:(NSURL *)url;
- (void)openURL:(NSURL *)url animated:(BOOL)animated;;


- (void)addStory:(PXYStory *)story handler:(UIViewController *(^)(NSURL *url, NSDictionary *params))handler;

@end
