//
//  NSNotificationCenter+Baymax.m
//  NetEaseBaymaxDemo
//
//  Created by Parsifal on 2017/3/13.
//  Copyright © 2017年 Parsifal. All rights reserved.
//

#import "NSNotificationCenter+Baymax.h"
#import "NSObject+Baymax.h"

@implementation NSNotificationCenter (Baymax)
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleInstanceMethodWithOriginSel:@selector(addObserver:selector:name:object:) swizzledSel:@selector(baymax_addObserver:selector:name:object:)];
    });
}

- (void)baymax_addObserver:(id)observer
                  selector:(SEL)aSelector
                      name:(NSNotificationName)aName
                    object:(id)anObject {
    NSObject *obj = observer;
    obj.didRegisteredNotificationCenter = YES;
    
    [self baymax_addObserver:observer
                    selector:aSelector
                        name:aName
                      object:anObject];
}
@end
