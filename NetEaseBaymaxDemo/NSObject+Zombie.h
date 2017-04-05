//
//  NSObject+Zombie.h
//  NetEaseBaymaxDemo
//
//  Created by Parsifal on 2017/4/3.
//  Copyright © 2017年 Parsifal. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (Zombie)

@property (copy, nonatomic) NSString *originalClassName;
@property (assign, nonatomic) BOOL needBadAccessProtector;

- (void)baymax_zombieDealloc;

@end
