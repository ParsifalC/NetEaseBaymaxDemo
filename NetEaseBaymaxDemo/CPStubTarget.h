//
//  CPStubTarget.h
//  NetEaseBaymaxDemo
//
//  Created by Parsifal on 2017/3/13.
//  Copyright © 2017年 Parsifal. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CPStubTarget : NSObject

@property (weak, nonatomic) NSTimer *weakTimer;
@property (weak, nonatomic) id weakTarget;
@property (assign, nonatomic) SEL weakSelector;

- (void)fireProxyTimer:(NSTimer *)userInfo;
@end
