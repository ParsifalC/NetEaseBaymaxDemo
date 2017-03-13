//
//  AppDelegate.m
//  NetEaseBaymaxDemo
//
//  Created by Parsifal on 2017/3/11.
//  Copyright © 2017年 Parsifal. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"

@interface AppDelegate ()
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //1、Test unrecognize selector
    NSObject *obj = [NSObject new];
    [obj performSelector:@selector(aaaa)];
    
    //2、Test KVO crash
    UIViewController *vc = self.window.rootViewController;
    //2-1:Cannot remove an observer <...> for the key path "keypath" from <...> because it is not registered as an observer.
    [vc removeObserver:self forKeyPath:@"title" context:nil];
    [vc removeObserver:self forKeyPath:@"title" context:nil];
    [vc addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial context:nil];
    
    //2-2:message sent to deallocated instance
    ViewController *avc = [ViewController new];
    avc.title = @"avc";
    [vc addObserver:avc forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
    
    //2-3:deallocated while key value observers were still registered with it.
    ViewController *bvc = [ViewController new];
    bvc.title = @"bvc";
    [bvc addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
    
    //3、Test NSNotification crash -- need iOS9 earlier system
    [[NSNotificationCenter defaultCenter] addObserver:avc selector:@selector(didReceivedNoti:) name:@"Noti" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:bvc selector:@selector(didReceivedNoti:) name:@"Noti" object:nil];
    
    //4、Test NSTimer crash
    ViewController *cvc = [ViewController new];
    cvc.title = @"cvc";
    [NSTimer scheduledTimerWithTimeInterval:1 target:cvc selector:@selector(fireTimer:) userInfo:@"I'm userInfo" repeats:YES];
    
    //5、Test Container crash
    //5-1:__NSArrayM
    NSMutableArray *mArray = [NSMutableArray new];
    [mArray addObject:nil];
    NSLog(@"%@", mArray[2]);
    
    //5-2:__NSArray0
    NSArray *aArray = @[];
    NSLog(@"%@", aArray[2]);
    
    //5-3:
    NSArray *bArray = @[@1];
    NSLog(@"%@", bArray[2]);
    
    //5-4:__NSArrayI
    NSArray *cArray = @[@1, @2];
    NSLog(@"%@", cArray[3]);
    
    //6、Test String crash
    NSString *astr = @"string";
    [astr substringFromIndex:astr.length];
    
    return YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@"%@", change);
}

@end
