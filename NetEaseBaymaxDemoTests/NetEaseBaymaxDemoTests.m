//
//  NetEaseBaymaxDemoTests.m
//  NetEaseBaymaxDemoTests
//
//  Created by Parsifal on 2017/3/13.
//  Copyright © 2017年 Parsifal. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSObject+Baymax.h"
#import "ViewController.h"
#import "ZombieTest.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
#pragma clang diagnostic ignored "-Wnonnull"
#pragma clang diagnostic ignored "-Wunused-variable"
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
#pragma clang diagnostic ignored "-Warc-unsafe-retained-assign"

@interface NetEaseBaymaxDemoTests : XCTestCase
@end

@implementation NetEaseBaymaxDemoTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testUnrecognizeSelector {
    //1、Test unrecognize selector
    // This won't throw exception
    XCTAssertNoThrow([[ViewController new] performSelector:@selector(crash)]);
    
    // This will throw a exception
    XCTAssertThrows([[NSObject new] performSelector:@selector(crash)]);
}

- (void)testKVO {
    //2、Test KVO crash
    //2-1:Cannot remove an observer <...> for the key path "keypath" from <...> because it is not registered as an observer.
    UIViewController *avc = [UIViewController new];
    XCTAssertNoThrow([avc removeObserver:self forKeyPath:@"title" context:nil]);
    XCTAssertNoThrow([avc removeObserver:self forKeyPath:@"title" context:nil]);

    //2-2:message sent to deallocated instance
    for (int i = 0; i < 3; i++) {
        UIViewController *bvc = [UIViewController new];
        [avc addObserver:bvc forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
    }
    
    avc.title = @"YOYO";

    //2-3:deallocated while key value observers were still registered with it.
    for (int i = 0; i < 3; i++) {
        UIViewController *cvc = [UIViewController new];
        [cvc addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
    }
}

- (void)testNSNotification {
    //3、Test NSNotification crash -- need iOS9 earlier system
    NSObject *obj = [NSObject new];
    
    [[NSNotificationCenter defaultCenter] addObserver:obj
                                             selector:@selector(notificationReceived:)
                                                 name:@"Noti"
                                               object:nil];
    
    XCTAssertTrue(obj.didRegisteredNotificationCenter);
    
    typeof(obj) __weak weakObj = obj;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssertNil(weakObj);
    });
}

- (void)testNSTimer {
    //4、Test NSTimer crash
    NSObject *obj = [NSObject new];
    
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:obj selector:@selector(fireTimer:) userInfo:@"I'm userInfo" repeats:YES];
    
    typeof(obj) __weak weakObj = obj;
    typeof(timer) __weak weakTimer = timer;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssertNil(weakObj);
        XCTAssertNil(weakTimer);
    });
}

- (void)testArray {
    //5、Test Container crash
    //5-1:__NSArrayM
    NSMutableArray *mArray = [NSMutableArray new];
    id nidObj = nil;
    XCTAssertNoThrow([mArray addObject:nidObj]);
    XCTAssertNoThrow(mArray[2]);
    
    //5-2:__NSArray0
    NSArray *aArray = @[];
    XCTAssertNoThrow(aArray[2]);
    
    //5-3:__NSSingleObjectArrayI
    NSArray *bArray = @[@1];
    XCTAssertNoThrow(bArray[2]);
    
    //5-4:__NSArrayI
    NSArray *cArray = @[@1, @2];
    XCTAssertNoThrow(cArray[3]);
}

- (void)testString {
    //6、Test String crash
    NSString *astr = @"string";
    XCTAssertNoThrow([astr substringFromIndex:astr.length]);
}

- (void)testBadAccess {
    //7 Test bad access crash
    for (int i = 0; i < 10; i++) {
        __unsafe_unretained ZombieTest *zombieObj;
        
        {
            zombieObj = [ZombieTest new];
        }
        
       XCTAssertNoThrow([zombieObj performSelector:@selector(crash)]);
    }
}

- (void)disable_testUIOnMainThread {
}

- (void)testPerformanceExample {
    [self measureBlock:^{
    }];
}

@end

#pragma clang diagnostic pop
