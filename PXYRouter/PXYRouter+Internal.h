//
//  PXYRouter+Internal.h
//  PXYRouterDemo
//
//  Created by 林 達也 on 2014/05/22.
//  Copyright (c) 2014年 林 達也. All rights reserved.
//

#import "PXYRouter.h"


@interface PXYRouterManager : NSObject
+ (instancetype)sharedManager;



- (BOOL)removeStory:(PXYStory *)story;


@end


