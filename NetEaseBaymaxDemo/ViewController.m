//
//  ViewController.m
//  NetEaseBaymaxDemo
//
//  Created by Parsifal on 2017/3/11.
//  Copyright © 2017年 Parsifal. All rights reserved.
//

#import "ViewController.h"
#import <objc/runtime.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)dealloc {
    NSLog(@"%@ %s", self.title, __FUNCTION__);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self changeTitle];
}

- (void)changeTitle {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.title = @(arc4random_uniform(100)+10).stringValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Noti" object:nil];
        [self changeTitle];
    });
}

- (void)didReceivedNoti:(NSNotification *)noti {
    NSLog(@"%@", noti);
}

- (void)fireTimer:(NSTimer *)userInfo {
    NSLog(@"userInfo:%@", userInfo);
}

@end
