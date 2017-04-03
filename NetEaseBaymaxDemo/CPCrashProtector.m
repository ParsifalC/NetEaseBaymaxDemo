//
//  CPCrashProtector.m
//  NetEaseBaymaxDemo
//
//  Created by Parsifal on 2017/4/3.
//  Copyright © 2017年 Parsifal. All rights reserved.
//

#import "CPCrashProtector.h"
#import <objc/runtime.h>

@interface CPCrashProtector ()

@property (strong, nonatomic) NSMutableArray *zombieCacheArray;
@property (strong, nonatomic) dispatch_queue_t zombieOperationQueue;

@end

@implementation CPCrashProtector

+ (instancetype)sharedInstance {
    static id sharedInstance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

- (void)freeZombie:(NSInteger)count {
    if (count) {
        NSMutableArray *freedZombies = [NSMutableArray new];
        NSUInteger safeCount = MIN(count, self.zombieCacheArray.count);
        
        for (int i = 0; i < safeCount; i++) {
            NSValue *value = self.zombieCacheArray[i];
            
            if (value) {
                [freedZombies addObject:value];
                id obj = [value nonretainedObjectValue];
                
                if (obj) {
                    @try {
                        // Get Original Dealloc IMP.
                        // See more in JSPatch:http://blog.cnbang.net/tech/3038/
                        Class objCls = object_getClass(obj);
                        Method deallocMethod = class_getInstanceMethod(objCls, NSSelectorFromString(@"baymax_dealloc"));
                        void (*originalDealloc)(__unsafe_unretained id, SEL) = (__typeof__(originalDealloc))method_getImplementation(deallocMethod);
                        originalDealloc(obj, NSSelectorFromString(@"dealloc"));
                    } @catch (NSException *exception) {
                        NSLog(@"Baymax Error!!!!!!!");
                    }
                }
            }
        }
        
        [self.zombieCacheArray removeObjectsInArray:freedZombies];
    }
}

- (void)asyncCacheZombie:(id)zombie {
    dispatch_async(self.zombieOperationQueue, ^{
        NSValue *value = [NSValue valueWithNonretainedObject:zombie];
        NSInteger zombieCount = self.zombieCacheArray.count;
        
        if (zombieCount >= kMaxZombieCacheCount) {
            [self freeZombie:MIN(kZombieFreedCountPerTime, zombieCount)];
            [self.zombieCacheArray addObject:value];
        } else {
            [self.zombieCacheArray addObject:value];
        }
    });
}

- (NSMutableArray *)zombieCacheArray {
    if (!_zombieCacheArray) {
        _zombieCacheArray = [NSMutableArray new];
    }
    
    return _zombieCacheArray;
}

- (dispatch_queue_t)zombieOperationQueue {
    if (!_zombieOperationQueue) {
        _zombieOperationQueue = dispatch_queue_create("ZombieOperationQueue", DISPATCH_QUEUE_SERIAL);
    }
    
    return _zombieOperationQueue;
}

@end
