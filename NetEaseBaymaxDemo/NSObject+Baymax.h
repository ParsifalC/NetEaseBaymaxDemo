//
//  NSObject+Baymax.h
//  NetEaseBaymaxDemo
//
//  Created by Parsifal on 2017/3/11.
//  Copyright © 2017年 Parsifal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CPKVODelegate.h"

@interface NSObject (BaymaxUtil)

+ (void)swizzleClassMethodWithOriginSel:(SEL)oriSel swizzledSel:(SEL)swiSel;
+ (void)swizzleInstanceMethodWithOriginSel:(SEL)oriSel swizzledSel:(SEL)swiSel;
- (BOOL)isMethodOverride:(Class)cls selector:(SEL)sel;
+ (BOOL)isMainBundleClass:(Class)cls;
+ (Class)addMethodToStubClass:(SEL)aSelector;

@end

@interface NSObject (Baymax)

@property (strong, nonatomic, readonly) id baymax;
@property (strong, nonatomic, readonly) CPKVODelegate *kvoDelegate;
@property (assign, nonatomic) BOOL didRegisteredNotificationCenter;

@end
