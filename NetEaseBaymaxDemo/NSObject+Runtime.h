//
//  NSObject+Runtime.h
//  NetEaseBaymaxDemo
//
//  Created by Parsifal on 2017/3/31.
//  Copyright © 2017年 Parsifal. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (Runtime)

+ (void)swizzleClassMethodWithOriginSel:(SEL)oriSel swizzledSel:(SEL)swiSel;
+ (void)swizzleInstanceMethodWithOriginSel:(SEL)oriSel swizzledSel:(SEL)swiSel;
- (BOOL)isMethodOverride:(Class)cls selector:(SEL)sel;
+ (BOOL)isMainBundleClass:(Class)cls;
+ (Class)addMethodToStubClass:(SEL)aSelector;

@end
