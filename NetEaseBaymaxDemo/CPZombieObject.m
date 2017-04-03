//
//  CPZombieObject.m
//  NetEaseBaymaxDemo
//
//  Created by Parsifal on 2017/3/31.
//  Copyright © 2017年 Parsifal. All rights reserved.
//

#import "CPZombieObject.h"
#import "NSObject+Baymax.h"
#import "NSObject+Zombie.h"

@implementation CPZombieObject

- (id)forwardingTargetForSelector:(SEL)aSelector {
    NSLog(@"Baymax Protector:message sent to deallocated instance:%@ %p", self.originalClassName, self);
//    NSLog(@"%@", [NSThread callStackSymbols]);

    Class baymaxProtector = [NSObject addMethodToStubClass:aSelector];
    
    if (!self.baymax) {
        self.baymax = [baymaxProtector new];
    }
    
    return self.baymax;
}

@end
