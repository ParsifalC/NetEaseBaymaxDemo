//
//  NSString+Baymax.m
//  NetEaseBaymaxDemo
//
//  Created by Parsifal on 2017/3/13.
//  Copyright © 2017年 Parsifal. All rights reserved.
//

#import "NSString+Baymax.h"
#import "NSObject+Baymax.h"

@implementation NSString (Baymax)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleInstanceMethodWithOriginSel:@selector(substringFromIndex:) swizzledSel:@selector(baymax_substringFromIndex:)];
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

@end
