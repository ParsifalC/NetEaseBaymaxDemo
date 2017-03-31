//
//  UIView+Baymax.m
//  NetEaseBaymaxDemo
//
//  Created by Parsifal on 2017/3/24.
//  Copyright © 2017年 Parsifal. All rights reserved.
//

#import "UIView+Baymax.h"
#import "NSObject+Baymax.h"

@implementation UIView (Baymax)

+ (void)load {
    [self swizzleInstanceMethodWithOriginSel:@selector(setNeedsDisplay) swizzledSel:@selector(baymax_setNeedsDisplay)];
    
    [self swizzleInstanceMethodWithOriginSel:@selector(setNeedsDisplayInRect:) swizzledSel:@selector(baymax_setNeedsDisplayInRect:)];
    
    [self swizzleInstanceMethodWithOriginSel:@selector(setNeedsLayout) swizzledSel:@selector(baymax_setNeedsLayout)];
}

- (void)baymax_setNeedsDisplay {
    if ([NSThread isMainThread]) {
        [self baymax_setNeedsDisplay];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self baymax_setNeedsDisplay];
        });
    }
}

- (void)baymax_setNeedsDisplayInRect:(CGRect)rect {
    if ([NSThread isMainThread]) {
        [self baymax_setNeedsDisplayInRect:rect];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self baymax_setNeedsDisplayInRect:rect];
        });
    }
}

- (void)baymax_setNeedsLayout {
    if ([NSThread isMainThread]) {
        [self baymax_setNeedsLayout];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self baymax_setNeedsLayout];
        });
    }
}

@end
