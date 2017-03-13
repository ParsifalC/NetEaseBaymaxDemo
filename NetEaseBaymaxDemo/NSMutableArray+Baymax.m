//
//  NSMutableArray+Baymax.m
//  NetEaseBaymaxDemo
//
//  Created by Parsifal on 2017/3/13.
//  Copyright © 2017年 Parsifal. All rights reserved.
//

#import "NSMutableArray+Baymax.h"
#import <objc/runtime.h>
#import "NSObject+Baymax.h"

@implementation NSMutableArray (Baymax)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class cls = objc_getClass("__NSArrayM");
        [cls swizzleInstanceMethodWithOriginSel:@selector(addObject:) swizzledSel:@selector(baymax_addObject:)];
        [cls swizzleInstanceMethodWithOriginSel:@selector(objectAtIndex:) swizzledSel:@selector(baymax_objectAtIndex:)];
    });
}

- (void)baymax_addObject:(id)anObject {
    if (anObject) {
        [self baymax_addObject:anObject];
    } else {
        NSLog(@"BaymaxProtector:insert nil obj");
    }
}


- (id)baymax_objectAtIndex:(NSUInteger)index {
    if (index < self.count) {
        return [self baymax_objectAtIndex:index];
    } else {
        NSLog(@"BaymaxProtector:Out Of Bounds");
        return nil;
    }
}

@end
