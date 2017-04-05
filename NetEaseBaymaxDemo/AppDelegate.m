//
//  AppDelegate.m
//  NetEaseBaymaxDemo
//
//  Created by Parsifal on 2017/3/11.
//  Copyright © 2017年 Parsifal. All rights reserved.
//

#import "AppDelegate.h"
#import "ZombieTest.h"

@interface AppDelegate ()
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    for (int i = 0; i < 10; i++) {
        __unsafe_unretained ZombieTest *zombieObj;
        
        {
            zombieObj = [ZombieTest new];
        }
        
        [zombieObj performSelector:@selector(crash)];
    }
    
    return YES;
}

@end
