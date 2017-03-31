//
//  NSString+Baymax.m
//  NetEaseBaymaxDemo
//
//  Created by Parsifal on 2017/3/13.
//  Copyright © 2017年 Parsifal. All rights reserved.
//

#import "NSString+Baymax.h"
#import "NSObject+Baymax.h"
#import <UIKit/UIKit.h>

@implementation NSString (Baymax)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleInstanceMethodWithOriginSel:@selector(substringFromIndex:) swizzledSel:@selector(baymax_substringFromIndex:)];
        [self swizzleInstanceMethodWithOriginSel:@selector(containsString:) swizzledSel:@selector(baymax_containsString:)];
    });
}

- (NSString *)baymax_substringFromIndex:(NSUInteger)from {
    if (from < self.length) {
        return [self baymax_substringFromIndex:from];
    } else {
        NSLog(@"BaymaxProtector:Out Of Length");
        return self;
    }
}

- (BOOL)baymax_containsString:(NSString *)str {
    if (str.length == 0) {
        return NO;
    }
    
    if ([[UIDevice currentDevice].systemVersion floatValue] < 8.0) {
        NSRange range = [self rangeOfString:str];
        return range.length != 0;
    } else {
        return [self baymax_containsString:str];
    }
}

@end
