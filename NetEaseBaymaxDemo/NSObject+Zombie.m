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
#import "CPCrashProtector.h"

@implementation NSObject (Zombie)

// MARK: Life Cycle
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleClassMethodWithOriginSel:@selector(allocWithZone:) swizzledSel:@selector(baymax_allocWithZone:)];
    });
}

+ (instancetype)baymax_allocWithZone:(struct _NSZone *)zone {
    NSObject *obj = [self baymax_allocWithZone:zone];
    
    if ([obj isMemberOfClass:NSClassFromString(@"ZombieTest")]) {
        obj.needBadAccessProtector = YES;
    }
    
    return obj;
}

- (void)zombieDelloc:(id)object {
    NSObject *castObj = (NSObject *)object;
    
    // Protect Bad Access crash
    if (castObj.needBadAccessProtector) {
        objc_destructInstance(castObj);
        object_setClass(castObj, [CPZombieObject class]);
        castObj.originalClassName = NSStringFromClass([object class]);
        
        [[CPCrashProtector sharedInstance] asyncCacheZombie:castObj];
    }
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
