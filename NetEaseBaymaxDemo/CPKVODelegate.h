//
//  CPKVODelegate.h
//  NetEaseBaymaxDemo
//
//  Created by Parsifal on 2017/3/12.
//  Copyright © 2017年 Parsifal. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CPKVOInfo : NSObject
@property (weak, nonatomic) id observer;
@end

@interface CPKVODelegate : NSObject
@property (strong, nonatomic) NSMutableDictionary *kvoInfoMaps;
@property (weak, nonatomic) id weakObservedObject;
@end
