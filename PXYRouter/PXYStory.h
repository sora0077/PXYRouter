//
//  PXYStory.h
//  PXYRouterDemo
//
//  Created by 林 達也 on 2014/05/09.
//  Copyright (c) 2014年 林 達也. All rights reserved.
//

#import <Foundation/Foundation.h>

//typedef NS_ENUM(NSInteger, PXYStorySegueType)
//{
//    PXYStorySegueTypePush,
//    PXYStorySegueTypeModal,
//};

typedef void (^PXYStorySegueHandler)(UIViewController *source, UIViewController *destination, BOOL animated);

@interface PXYStory : NSObject

+ (instancetype)storyWithPattern:(NSString *)pattern
                           segue:(PXYStorySegueHandler)segue
                          unwind:(PXYStorySegueHandler)unwind;

+ (instancetype)apiWithPattern:(NSString *)pattern;

@property (nonatomic, readonly) NSString *pattern;

@end
