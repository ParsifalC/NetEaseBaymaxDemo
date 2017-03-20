//
//  NSObject+Baymax.m
//  NetEaseBaymaxDemo
//
//  Created by Parsifal on 2017/3/11.
//  Copyright © 2017年 Parsifal. All rights reserved.
//

#import "NSObject+Baymax.h"
#import <objc/runtime.h>
#import "CPKVODelegate.h"

char * const kBaymaxProtectorName = "kBaymaxProtector";

void baymaxProtected(id self, SEL sel) {
}

@implementation NSObject (BaymaxUtil)

// MARK: Util
+ (void)swizzleClassMethodWithOriginSel:(SEL)oriSel swizzledSel:(SEL)swiSel {
    Class cls = object_getClass(self);
    Method originAddObserverMethod = class_getClassMethod(cls, oriSel);
    Method swizzledAddObserverMethod = class_getClassMethod(cls, swiSel);
    
    [self swizzleMethodWithOriginSel:oriSel oriMethod:originAddObserverMethod swizzledSel:swiSel swizzledMethod:swizzledAddObserverMethod class:cls];
}

+ (void)swizzleInstanceMethodWithOriginSel:(SEL)oriSel swizzledSel:(SEL)swiSel {
    Method originAddObserverMethod = class_getInstanceMethod(self, oriSel);
    Method swizzledAddObserverMethod = class_getInstanceMethod(self, swiSel);
    
    [self swizzleMethodWithOriginSel:oriSel oriMethod:originAddObserverMethod swizzledSel:swiSel swizzledMethod:swizzledAddObserverMethod class:self];
}

+ (void)swizzleMethodWithOriginSel:(SEL)oriSel
                         oriMethod:(Method)oriMethod
                       swizzledSel:(SEL)swizzledSel
                    swizzledMethod:(Method)swizzledMethod
                             class:(Class)cls {
    BOOL didAddMethod = class_addMethod(cls, oriSel, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(cls, swizzledSel, method_getImplementation(oriMethod), method_getTypeEncoding(oriMethod));
    } else {
        method_exchangeImplementations(oriMethod, swizzledMethod);
    }
}

+ (Class)addMethodToStubClass:(SEL)aSelector {
    Class baymaxProtector = objc_getClass(kBaymaxProtectorName);
    
    if (!baymaxProtector) {
        baymaxProtector = objc_allocateClassPair([NSObject class], kBaymaxProtectorName, sizeof([NSObject class]));
        objc_registerClassPair(baymaxProtector);
    }
    
    class_addMethod(baymaxProtector, aSelector, (IMP)baymaxProtected, "v@:");
    return baymaxProtector;
}

+ (BOOL)isClassMethodOverride:(Class)cls selector:(SEL)selector {
    Method selfMethod = class_getClassMethod(cls, selector);
    Method superMethod = class_getClassMethod(class_getSuperclass(cls), selector);
    
    return selfMethod != superMethod;
}

+ (BOOL)isInstanceMethodOverride:(Class)cls selector:(SEL)selector {
    Method selfMethod = class_getInstanceMethod(cls, selector);
    Method superMethod = class_getInstanceMethod(class_getSuperclass(cls), selector);
    
    return selfMethod != superMethod;
}

+ (BOOL)isMainBundleClass:(Class)cls {
    return cls && [[NSBundle bundleForClass:cls] isEqual:[NSBundle mainBundle]];
}

@end

@implementation NSObject (Baymax)

// MARK: Life cycle
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleInstanceMethodWithOriginSel:@selector(forwardingTargetForSelector:) swizzledSel:@selector(baymax_forwardingTargetForSelector:)];
        
        [self swizzleInstanceMethodWithOriginSel:@selector(addObserver:forKeyPath:options:context:) swizzledSel:@selector(baymax_addObserver:forKeyPath:options:context:)];
        
        [self swizzleInstanceMethodWithOriginSel:@selector(removeObserver:forKeyPath:context:) swizzledSel:@selector(baymax_removeObserver:forKeyPath:context:)];
        
        [self swizzleInstanceMethodWithOriginSel:NSSelectorFromString(@"dealloc") swizzledSel:@selector(baymax_dealloc)];
    });
}

- (void)baymax_dealloc {
    for (NSString *keypath in self.kvoDelegate.kvoInfoMaps) {
        [self baymax_removeObserver:self.kvoDelegate forKeyPath:keypath context:nil];
    }
    
    objc_setAssociatedObject(self, @selector(kvoDelegate), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (self.didRegisteredNotificationCenter) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    
    [self baymax_dealloc];
}

// MARK: Unrecognize Selector Protected
- (id)baymax_forwardingTargetForSelector:(SEL)aSelector {
    // Ignore class which has overrided forwardInvocation method and System classes
    if ([NSObject isInstanceMethodOverride:[self class] selector:@selector(forwardInvocation:)] ||
        ![NSObject isMainBundleClass:[self class]]) {
        return [self baymax_forwardingTargetForSelector:aSelector];
    }
    
    NSLog(@"catch unrecognize selector crash %@ %@", self, NSStringFromSelector(aSelector));
    
    Class baymaxProtector = [NSObject addMethodToStubClass:aSelector];
    
    if (!self.baymax) {
        self.baymax = [baymaxProtector new];
    }
    
    return self.baymax;
}

- (void)setBaymax:(id)baymax {
    objc_setAssociatedObject(self, @selector(baymax), baymax, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id)baymax {
    return objc_getAssociatedObject(self, _cmd);
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
    objc_setAssociatedObject(self, @selector(didRegisteredNotificationCenter), @(didRegisteredNotificationCenter), OBJC_ASSOCIATION_ASSIGN);
}

- (BOOL)didRegisteredNotificationCenter {
    NSNumber *result = objc_getAssociatedObject(self, _cmd);
    return result.boolValue;
}

@end
