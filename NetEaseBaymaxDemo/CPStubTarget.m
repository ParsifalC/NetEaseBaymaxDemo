//
//  CPStubTarget.m
//  NetEaseBaymaxDemo
//
//  Created by Parsifal on 2017/3/13.
//  Copyright © 2017年 Parsifal. All rights reserved.
//

#import "CPStubTarget.h"

@implementation CPStubTarget

- (void)fireProxyTimer:(NSTimer *)userInfo {
    if (self.weakTarget) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.weakTarget performSelector:self.weakSelector withObject:userInfo];
#pragma clang diagnostic pop
    } else {
        [self.weakTimer invalidate];
        self.weakTimer = nil;
    }
}

@end
