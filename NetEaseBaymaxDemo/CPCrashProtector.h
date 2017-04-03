//
//  CPCrashProtector.h
//  NetEaseBaymaxDemo
//
//  Created by Parsifal on 2017/4/3.
//  Copyright © 2017年 Parsifal. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kMaxZombieCacheCount 4
#define kZombieFreedCountPerTime 2

@interface CPCrashProtector : NSObject

+ (instancetype)sharedInstance;
- (void)freeZombie:(NSInteger)count;
- (void)asyncCacheZombie:(id)zombie;

@end
