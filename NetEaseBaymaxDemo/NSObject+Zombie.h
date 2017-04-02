//
//  NSObject+Zombie.h
//  NetEaseBaymaxDemo
//
//  Created by Parsifal on 2017/3/31.
//  Copyright © 2017年 Parsifal. All rights reserved.
//

#import <Foundation/Foundation.h>

static char kOriginalClassNameKey;

@interface NSObject (Zombie)

@property (assign, nonatomic) BOOL needBadAccessProtector;
@property (copy, nonatomic) NSString *originalClassName;

@end
