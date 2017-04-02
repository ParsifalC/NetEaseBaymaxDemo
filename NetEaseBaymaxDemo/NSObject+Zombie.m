//
//  NSObject+Zombie.m
//  NetEaseBaymaxDemo
//
//  Created by Parsifal on 2017/3/31.
//  Copyright © 2017年 Parsifal. All rights reserved.
//

#import "NSObject+Zombie.h"
#import <objc/runtime.h>
#import "NSObject+Runtime.h"
#import "NSObject+Baymax.h"
#import "CPZombieObject.h"


@implementation NSObject (Zombie)

// MARK: Life Cycle
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleClassMethodWithOriginSel:@selector(allocWithZone:) swizzledSel:@selector(baymax_allocWithZone:)];
        
        [self swizzleInstanceMethodWithOriginSel:@selector(dealloc) swizzledSel:@selector(baymax_dealloc)];
    });
}

+ (instancetype)baymax_allocWithZone:(struct _NSZone *)zone {
    NSObject *obj = [self baymax_allocWithZone:zone];
    
    if ([obj isMemberOfClass:NSClassFromString(@"ZombieTest")]) {
        obj.needBadAccessProtector = YES;
    }
    
    return obj;
}

- (void)baymax_dealloc {
    // Protect Bad Access crash
    if (self.needBadAccessProtector) {
        // TODO: Memory Management
        objc_destructInstance(self);
        object_setClass(self, [CPZombieObject class]);
        self.originalClassName = NSStringFromClass([self class]);
    } else {
        [self baymax_dealloc];
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
