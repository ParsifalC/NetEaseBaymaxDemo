//
//  NSObject+Baymax.m
//  NetEaseBaymaxDemo
//
//  Created by Parsifal on 2017/3/11.
//  Copyright © 2017年 Parsifal. All rights reserved.
//

#import "NSObject+Baymax.h"
#import <objc/runtime.h>
#import "NSObject+Zombie.h"

@implementation NSObject (Baymax)

// MARK: Life cycle
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleInstanceMethodWithOriginSel:@selector(forwardingTargetForSelector:) swizzledSel:@selector(baymax_forwardingTargetForSelector:)];
//
//        [self swizzleInstanceMethodWithOriginSel:@selector(addObserver:forKeyPath:options:context:) swizzledSel:@selector(baymax_addObserver:forKeyPath:options:context:)];
//        
//        [self swizzleInstanceMethodWithOriginSel:@selector(removeObserver:forKeyPath:context:) swizzledSel:@selector(baymax_removeObserver:forKeyPath:context:)];
        
//        [self swizzleInstanceMethodWithOriginSel:NSSelectorFromString(@"dealloc") swizzledSel:@selector(baymax_dealloc)];
    });
}

//- (void)baymax_dealloc {
//    for (NSString *keypath in self.kvoDelegate.kvoInfoMaps) {
//        [self baymax_removeObserver:self.kvoDelegate forKeyPath:keypath context:nil];
//    }
//    
//    objc_setAssociatedObject(self, @selector(kvoDelegate), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
//    
//    // Protect NSNotificationCenter crash
//    if (self.didRegisteredNotificationCenter) {
//        [[NSNotificationCenter defaultCenter] removeObserver:self];
//    }
//    
//    [self baymax_dealloc];
//}

// MARK: Getter & Setter
- (void)setBaymax:(id)baymax {
    objc_setAssociatedObject(self, @selector(baymax), baymax, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id)baymax {
    return objc_getAssociatedObject(self, _cmd);
}

// MARK: Unrecognize Selector Protected
- (id)baymax_forwardingTargetForSelector:(SEL)aSelector {
    // Ignore class which has overrided forwardInvocation method and System classes
    if ([self isMethodOverride:[self class] selector:@selector(forwardInvocation:)]||
        ![NSObject isMainBundleClass:[self class]]) {
        return [self baymax_forwardingTargetForSelector:aSelector];
    }
    
    if (self.originalClassName.length) {
        NSLog(@"Baymax Protect:message sent to deallocated instance:%@ %p", self.originalClassName, self);
    } else {
        NSLog(@"catch unrecognize selector crash %@ %@", self, NSStringFromSelector(aSelector));
    }
    
    Class baymaxProtector = [NSObject addMethodToStubClass:aSelector];
    
    if (!self.baymax) {
        self.baymax = [baymaxProtector new];
    }
    
    return self.baymax;
}

// MARK: KVO Protected
- (void)baymax_addObserver:(NSObject *)observer
                forKeyPath:(NSString *)keyPath
                   options:(NSKeyValueObservingOptions)options
                   context:(void *)context {
    if (keyPath.length == 0 || !observer) {
        NSLog(@"Add Observer Error:Check KVO KeyPath OR Observer");
        return;
    }
    
    if (!self.kvoDelegate) {
        self.kvoDelegate = [CPKVODelegate new];
    }
    
    CPKVODelegate *kvoDelegate = self.kvoDelegate;
    NSMutableDictionary *kvoInfoMaps = kvoDelegate.kvoInfoMaps;
    NSMutableArray *infoArray = kvoInfoMaps[keyPath];
    CPKVOInfo *kvoInfo = [CPKVOInfo new];
    kvoInfo.observer = observer;

    if (infoArray.count) {
        BOOL didAddObserver = NO;
        
        for (CPKVOInfo *info in infoArray) {
            if (info.observer == observer) {
                didAddObserver = YES;
                break;
            }
        }
        
        if (didAddObserver) {
            NSLog(@"BaymaxKVOProtector:%@ Has added Already", observer);
        } else {
            [infoArray addObject:kvoInfo];
        }
    } else {
        infoArray = [NSMutableArray new];
        [infoArray addObject:kvoInfo];
        kvoInfoMaps[keyPath] = infoArray;
        [self baymax_addObserver:kvoDelegate forKeyPath:keyPath options:options context:context];
    }
}

- (void)baymax_removeObserver:(NSObject *)observer
                   forKeyPath:(NSString *)keyPath
                      context:(void *)context {
    if (keyPath.length == 0 || !observer) {
        NSLog(@"Remove Observer Error:Check KVO KeyPath OR Observer");
        return;
    }
    
    CPKVODelegate *kvoDelegate = self.kvoDelegate;
    NSMutableDictionary *kvoInfoMaps = kvoDelegate.kvoInfoMaps;
    NSMutableArray *infoArray = kvoInfoMaps[keyPath];
    
    if (infoArray.count) {
        NSMutableArray *matchedInfos = [NSMutableArray new];
        
        for (CPKVOInfo *info in infoArray) {
            if (info.observer == observer || info.observer == nil) {
                [matchedInfos addObject:info];
            }
        }
        
        [infoArray removeObjectsInArray:matchedInfos];
        
        if (infoArray.count == 0) {
            [kvoInfoMaps removeObjectForKey:keyPath];
            [self baymax_removeObserver:kvoDelegate forKeyPath:keyPath context:context];
        }
    } else {
        NSLog(@"BaymaxKVOProtector:Obc has removed already!");
        [kvoInfoMaps removeObjectForKey:keyPath];
    }
}

- (void)setKvoDelegate:(CPKVODelegate *)kvoDelegate {
    objc_setAssociatedObject(self, @selector(kvoDelegate), kvoDelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CPKVODelegate *)kvoDelegate {
    return objc_getAssociatedObject(self, _cmd);
}

// MARK: NSNotification Protected
- (void)setDidRegisteredNotificationCenter:(BOOL)didRegisteredNotificationCenter {
    objc_setAssociatedObject(self, @selector(didRegisteredNotificationCenter), @(didRegisteredNotificationCenter), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)didRegisteredNotificationCenter {
    NSNumber *result = objc_getAssociatedObject(self, _cmd);
    return result.boolValue;
}

@end
