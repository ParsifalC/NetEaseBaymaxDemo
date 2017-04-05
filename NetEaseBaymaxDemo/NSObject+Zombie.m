//
//  NSObject+Zombie.m
//  NetEaseBaymaxDemo
//
//  Created by Parsifal on 2017/4/3.
//  Copyright © 2017年 Parsifal. All rights reserved.
//

#import "NSObject+Zombie.h"
#import <objc/runtime.h>
#import "NSObject+Baymax.h"
#import "CPZombieObject.h"

static NSMutableArray *zombieCacheArray;
static dispatch_queue_t zombieOperationQueue;

static void freeZombie(NSInteger count) {
    if (count) {
        NSMutableArray *freedZombies = [NSMutableArray new];
        NSUInteger safeCount = MIN(count, zombieCacheArray.count);
        
        for (int i = 0; i < safeCount; i++) {
            NSValue *value = zombieCacheArray[i];
            
            if (value) {
                [freedZombies addObject:value];
                id obj = [value nonretainedObjectValue];
                
                if (obj) {
                    @try {
                        // Get Original Dealloc IMP.
                        // See more in JSPatch:https://github.com/bang590/JSPatch/blob/master/JSPatch/JPEngine.m
                        Class objCls = object_getClass(obj);
                        Method deallocMethod = class_getInstanceMethod(objCls, NSSelectorFromString(@"baymax_dealloc"));
                        void (*originalDealloc)(__unsafe_unretained id, SEL) = (__typeof__(originalDealloc))method_getImplementation(deallocMethod);
                        NSLog(@"%@ %p rc:%@", obj, originalDealloc, @(CFGetRetainCount((__bridge CFTypeRef)(obj))));
                        originalDealloc(obj, NSSelectorFromString(@"dealloc"));
                    } @catch (NSException *exception) {
                        NSLog(@"Baymax Error!!!!!!!Exception: %@", exception);
                    }
                }
            }
        }
        
        [zombieCacheArray removeObjectsInArray:freedZombies];
        [freedZombies release];
    }
}

@implementation NSObject (Zombie)

// MARK: Life Cycle
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleClassMethodWithOriginSel:@selector(allocWithZone:) swizzledSel:@selector(baymax_allocWithZone:)];
        zombieCacheArray = [NSMutableArray new];
        zombieOperationQueue = dispatch_queue_create("ZombieOperationQueue", DISPATCH_QUEUE_SERIAL);
    });
}

+ (instancetype)baymax_allocWithZone:(struct _NSZone *)zone {
    NSObject *obj = [self baymax_allocWithZone:zone];
    
    if ([obj isMemberOfClass:NSClassFromString(@"ZombieTest")]) {
        obj.needBadAccessProtector = YES;
    }
    
    return obj;
}

- (void)baymax_zombieDealloc {
    NSObject *castObj = (NSObject *)self;
    // Protect Bad Access crash
    objc_destructInstance(self);
    object_setClass(self, [CPZombieObject class]);
    castObj.originalClassName = NSStringFromClass([self class]);
    
    dispatch_async(zombieOperationQueue, ^{
        NSValue *value = [NSValue valueWithNonretainedObject:self];
        NSInteger zombieCount = zombieCacheArray.count;
        
        if (zombieCount >= kMaxZombieCacheCount) {
            freeZombie(MIN(kZombieFreedCountPerTime, zombieCount));
        }
        
        [zombieCacheArray addObject:value];
    });
}

// MARK: Setter & Getter
- (void)setOriginalClassName:(NSString *)originalClassName {
    objc_setAssociatedObject(self, @selector(originalClassName), originalClassName, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)originalClassName {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setNeedBadAccessProtector:(BOOL)needBadAccessProtector {
    objc_setAssociatedObject(self, @selector(needBadAccessProtector), @(needBadAccessProtector), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)needBadAccessProtector {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

@end
