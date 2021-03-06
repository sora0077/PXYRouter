//
//  PXYAppDelegate.m
//  PXYRouterDemo
//
//  Created by 林 達也 on 2014/05/09.
//  Copyright (c) 2014年 林 達也. All rights reserved.
//

#import "PXYAppDelegate.h"

#import <Aspects/Aspects.h>

#import "PXYRouter.h"
#import "PXYRouter+Internal.h"

@implementation PXYAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.

    [(id)application.delegate aspect_hookSelector:@selector(applicationDidBecomeActive:)
                         withOptions:AspectPositionAfter | AspectOptionAutomaticRemoval
                          usingBlock:^(id<AspectInfo> aspectInfo, UIApplication *application) {
                              NSLog(@"1");
                          }
                               error:NULL];

    [(id)application.delegate aspect_hookSelector:@selector(applicationDidBecomeActive:)
                                      withOptions:AspectPositionAfter | AspectOptionAutomaticRemoval
                          usingBlock:^(id<AspectInfo> aspectInfo, UIApplication *application) {
                              NSLog(@"2");
                          }
                               error:NULL];

    [(id)application.delegate aspect_hookSelector:@selector(applicationDidBecomeActive:)
                                      withOptions:AspectPositionAfter | AspectOptionAutomaticRemoval
                          usingBlock:^(id<AspectInfo> aspectInfo, UIApplication *application) {
                              NSLog(@"3");
                          }
                               error:NULL];

    [PXYRouter routingOnWindow:self.window];

    PXYStory *story = [PXYStory storyWithPattern:@"/modal/viewcontroller/:color"
                                           segue:^(UIViewController *source, UIViewController *destination, BOOL animated) {
                                               [source presentViewController:destination animated:animated completion:nil];
                                           }
                                          unwind:^(UIViewController *source, UIViewController *destination, BOOL animated) {
                                              [destination dismissViewControllerAnimated:animated completion:nil];
                                          }];
//    [story waitUntilFinished:YES];
    [[PXYRouter scheme:@"app"] addStory:story handler:^UIViewController *(NSURL *url, NSDictionary *params) {
        UIViewController *viewController = [UIViewController new];
        viewController.view.backgroundColor = [UIColor performSelector:NSSelectorFromString(params[@"color"])];
        return viewController;
    }];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [PXYRouter openURL:[NSURL URLWithString:@"app://modal/viewcontroller/yellowColor"]
                  animated:NO];
        [PXYRouter openURL:[NSURL URLWithString:@"app://modal/viewcontroller/redColor"]
                  animated:NO];
        [PXYRouter openURL:[NSURL URLWithString:@"app://modal/viewcontroller/blueColor"]];
        [PXYRouter openURL:[NSURL URLWithString:@"app://modal/viewcontroller/redColor"]];
        [PXYRouter pop:NO];
        [PXYRouter pop:NO];
        [PXYRouter openURL:[NSURL URLWithString:@"app://modal/viewcontroller/blueColor"]
                  animated:NO];
        [PXYRouter openURL:[NSURL URLWithString:@"app://modal/viewcontroller/redColor"]
                  animated:NO];
        [PXYRouter openURL:[NSURL URLWithString:@"app://modal/viewcontroller/blueColor"]
                  animated:NO];
        [PXYRouter openURL:[NSURL URLWithString:@"app://modal/viewcontroller/redColor"]
                  animated:NO];
        [PXYRouter openURL:[NSURL URLWithString:@"app://modal/viewcontroller/blueColor"]];

        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [PXYRouter pop];

            [PXYRouter pop:NO];
//            [PXYRouter pop:NO];
//            [PXYRouter pop:NO];
//            [PXYRouter pop:NO];
//            [PXYRouter pop:NO];
//            [PXYRouter pop:NO];
//            [PXYRouter pop:NO];
//            [PXYRouter pop:NO];

            [self.window.rootViewController dismissViewControllerAnimated:YES completion:^{
            }];
        });
    });


    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
