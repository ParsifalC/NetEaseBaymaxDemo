//
//  ViewController.h
//  NetEaseBaymaxDemo
//
//  Created by Parsifal on 2017/3/11.
//  Copyright © 2017年 Parsifal. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

- (void)didReceivedNoti:(NSNotification *)noti;
- (void)fireTimer:(NSTimer *)userInfo;

@end

