//
//  CPKVODelegate.m
//  NetEaseBaymaxDemo
//
//  Created by Parsifal on 2017/3/12.
//  Copyright © 2017年 Parsifal. All rights reserved.
//

#import "CPKVODelegate.h"
#import "NSObject+Baymax.h"

@implementation CPKVOInfo

@end

@interface CPKVODelegate ()

@end

@implementation CPKVODelegate
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleInstanceMethodWithOriginSel:@selector(observeValueForKeyPath:ofObject:change:context:) swizzledSel:@selector(baymax_observeValueForKeyPath:ofObject:change:context:)];
    });
}

- (void)baymax_observeValueForKeyPath:(NSString *)keyPath
                             ofObject:(id)object
                               change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                              context:(void *)context {
    NSMutableDictionary *kvoInfoMaps = self.kvoInfoMaps;
    NSMutableArray *infoArray = kvoInfoMaps[keyPath];
    NSMutableArray *invalidInfos = [NSMutableArray new];
    
    for (CPKVOInfo *info in infoArray) {
        if (!info.observer) {
            [invalidInfos addObject:info];
        } else {
            [info.observer observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        }
    }
    
    [infoArray removeObjectsInArray:invalidInfos];
}

- (NSMutableDictionary *)kvoInfoMaps {
    if (!_kvoInfoMaps) {
        _kvoInfoMaps = [NSMutableDictionary new];
    }
    
    return _kvoInfoMaps;
}
@end
