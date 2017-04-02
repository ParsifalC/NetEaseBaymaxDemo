//
//  NSObject+Runtime.m
//  NetEaseBaymaxDemo
//
//  Created by Parsifal on 2017/3/31.
//  Copyright © 2017年 Parsifal. All rights reserved.
//

#import "NSObject+Runtime.h"
#import <objc/runtime.h>

char * const kBaymaxProtectorName = "kBaymaxProtector";

void baymaxProtected(id self, SEL sel) {
}

@implementation NSObject (Runtime)

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

- (BOOL)isMethodOverride:(Class)cls selector:(SEL)sel {
    IMP clsIMP = class_getMethodImplementation(cls, sel);
    IMP superClsIMP = class_getMethodImplementation([cls superclass], sel);
    
    return clsIMP != superClsIMP;
}

+ (BOOL)isMainBundleClass:(Class)cls {
    return cls && [[NSBundle bundleForClass:cls] isEqual:[NSBundle mainBundle]];
}

@end
