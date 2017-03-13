//
//  NSObject+Baymax.h
//  NetEaseBaymaxDemo
//
//  Created by Parsifal on 2017/3/11.
//  Copyright © 2017年 Parsifal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CPKVODelegate.h"

@interface NSObject (Baymax)

@property (strong, nonatomic, readonly) id baymax;
@property (strong, nonatomic, readonly) CPKVODelegate *kvoDelegate;
@property (assign, nonatomic) BOOL didRegisteredNotificationCenter;

+ (void)swizzleClassMethodWithOriginSel:(SEL)oriSel swizzledSel:(SEL)swiSel;
+ (void)swizzleInstanceMethodWithOriginSel:(SEL)oriSel swizzledSel:(SEL)swiSel;

@end
