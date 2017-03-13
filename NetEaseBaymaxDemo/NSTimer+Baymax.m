//
//  NSTimer+Baymax.m
//  NetEaseBaymaxDemo
//
//  Created by Parsifal on 2017/3/13.
//  Copyright © 2017年 Parsifal. All rights reserved.
//

#import "NSTimer+Baymax.h"
#import "NSObject+Baymax.h"
#import "CPStubTarget.h"

@implementation NSTimer (Baymax)
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleClassMethodWithOriginSel:@selector(scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:) swizzledSel:@selector(baymax_scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:)];
    });
}

+ (NSTimer *)baymax_scheduledTimerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(id)userInfo repeats:(BOOL)yesOrNo {
    if (yesOrNo) {
        CPStubTarget *stubTarget = [CPStubTarget new];
        stubTarget.weakTarget = aTarget;
        stubTarget.weakSelector = aSelector;
        stubTarget.weakTimer = [self baymax_scheduledTimerWithTimeInterval:ti target:stubTarget selector:@selector(fireProxyTimer:) userInfo:userInfo repeats:YES];
        return stubTarget.weakTimer;
    } else {
        return [self baymax_scheduledTimerWithTimeInterval:ti target:aTarget selector:aSelector userInfo:userInfo repeats:yesOrNo];
    }
}
@end
