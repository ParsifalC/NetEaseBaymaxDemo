//
//  NSArray+Baymax.m
//  NetEaseBaymaxDemo
//
//  Created by Parsifal on 2017/3/13.
//  Copyright © 2017年 Parsifal. All rights reserved.
//

#import "NSArray+Baymax.h"
#import <objc/runtime.h>
#import "NSObject+Baymax.h"

@implementation NSArray (Baymax)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [objc_getClass("__NSArray0") swizzleInstanceMethodWithOriginSel:@selector(objectAtIndex:) swizzledSel:@selector(baymax_empty_objectAtIndex:)];
        
        [objc_getClass("__NSSingleObjectArrayI") swizzleInstanceMethodWithOriginSel:@selector(objectAtIndex:) swizzledSel:@selector(baymax_singel_objectAtIndex:)];

        [objc_getClass("__NSArrayI") swizzleInstanceMethodWithOriginSel:@selector(objectAtIndex:) swizzledSel:@selector(baymax_objectAtIndex:)];
    });
}

- (id)baymax_empty_objectAtIndex:(NSUInteger)index {
    NSLog(@"BaymaxProtector:Out Of Bounds");
    return nil;
}

- (id)baymax_singel_objectAtIndex:(NSUInteger)index {
    if (index > 0) {
        NSLog(@"BaymaxProtector:Out Of Bounds");
    }
    
    return [self baymax_singel_objectAtIndex:0];
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
