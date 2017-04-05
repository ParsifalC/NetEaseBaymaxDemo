//
//  NSObject+Baymax.h
//  NetEaseBaymaxDemo
//
//  Created by Parsifal on 2017/3/11.
//  Copyright © 2017年 Parsifal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CPKVODelegate.h"
#import "NSObject+Runtime.h"

#define kMaxZombieCacheCount 4
#define kZombieFreedCountPerTime 2

@interface NSObject (Baymax)

@property (retain, nonatomic) id baymax;
@property (retain, nonatomic, readonly) CPKVODelegate *kvoDelegate;
@property (assign, nonatomic) BOOL didRegisteredNotificationCenter;

@end
