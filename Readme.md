# NetEaseBaymaxDemo
原文：[大白健康系统--iOS APP运行时Crash自动修复系统](https://neyoufan.github.io/2017/01/13/ios/BayMax_HTSafetyGuard/)，看过原文后，觉得挺有意思的，是一个不错的Runtime实践用例。这个Repo是根据原文提供方案仿写的小Demo，仅做讨论研究讨论使用，期待官方早日完成测试开源SDK，学习下源码。**这里不讨论这种防护是否有必要，仅当学习练手之用。**
## TODO
- [ ] Unit Test
- [ ] Bad Access 防护
- [ ] UI Not On Main Thread 防护

## 关于仿写过程中网易Baymax的一些疑问：
#### 1、Unrecognized Selector类型crash防护
以下是我根据Baymax思路仿写的：

```swift
- (id)forwardingTargetForSelector:(SEL)aSelector {
    Class baymaxProtector = objc_getClass(kBaymaxProtectorName);
    if (!baymaxProtector) {
        baymaxProtector = objc_allocateClassPair([NSObject class], kBaymaxProtectorName, sizeof([NSObject class]));
        objc_registerClassPair(baymaxProtector);
    }
    class_addMethod(baymaxProtector, aSelector, (IMP)baymaxProtected, "v@:");
    if (!self.baymax) {
        self.baymax = [baymaxProtector new];
    }
    return self.baymax;
}
```
有以下两个疑问：


1）文中提到`注意如果对象的类本身如果重写了forwardInvocation方法的话，就不应该对forwardingTargetForSelector进行重写了，否则会影响到该类型的对象原本的消息转发流程。`这部分似乎并不能在这里通过代码判断。`[self respondsToSelector:@selector(forwardInvocation:)]`返回的始终是YES。Baymax目前是通过什么方式来排除这种情况的呢？


2）关于桩类对象的释放问题，通过手动`objc_registerClassPair:`创建的类对象，只能通过`objc_disposeClassPair:`手动释放。这里的类对象，是否直到程序结束由系统回收，运行过程中不做释放呢（虽然占据内存也不是很大）？或者再复写`dealloc`方法，从这里做回收（这样似乎也没有必要，如果出现多次crash，就会有反复创建和销毁操作）？


#### 2、KVO类型crash防护
关于KVO部分，Facebook之前有出过小工具，思路与这个有点类似，都是通过中间层来转发消息，[KVOController](https://github.com/facebook/KVOController)。根据原文方案，这里也是通过增加`CPKVODelegate`作代理，转发消息实现。为每个被观察对象添加一个代理，以这个代理作为实际的观察者，所有的消息都会发往这个观察者然后再处理派发。主要针对以下三种crash情况：


- 移除一个非观察者：`Cannot remove an observer <...> for the key path "keypath" from <...> because it is not registered as an observer.`
- 观察者释放后，未从观察者KVO中移除：`message sent to deallocated instance`
- 被观察者释放后，未移除其所有观察者：`deallocated while key value observers were still registered with it.`
这一部分我的疑问是：

1）由于Hook的是`NSObject`这个基类，系统内部的一些实现也是会使用KVO。在写这个Demo的时候，我也发现，系统在启动阶段也会调用几次的`addObserver..`方法。那么我的疑问是，这样做转发后，在实际运用中，如果大范围的使用KVO，损失的效率会明显吗？希望到时候能分享下实践过程遇到的坑。

我的实现代码如下：


```swift
//NSObject (Baymax)
- (void)setKvoDelegate:(CPKVODelegate *)kvoDelegate {
    objc_setAssociatedObject(self, @selector(kvoDelegate), kvoDelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CPKVODelegate *)kvoDelegate {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)baymax_addObserver:(NSObject *)observer
                forKeyPath:(NSString *)keyPath
                   options:(NSKeyValueObservingOptions)options
                   context:(void *)context {
    if (keyPath.length == 0 || !observer) {
        NSLog(@"Add Observer Error:Check KVO KeyPath OR Observer");
        return;
    }
    
    if (!self.kvoDelegate) {
        self.kvoDelegate = [CPKVODelegate new];
    }
    
    CPKVODelegate *kvoDelegate = self.kvoDelegate;
    NSMutableDictionary *kvoInfoMaps = kvoDelegate.kvoInfoMaps;
    NSMutableArray *infoArray = kvoInfoMaps[keyPath];
    CPKVOInfo *kvoInfo = [CPKVOInfo new];
    kvoInfo.observer = observer;

    if (infoArray.count) {
        BOOL didAddObserver = NO;
        
        for (CPKVOInfo *info in infoArray) {
            if (info.observer == observer) {
                didAddObserver = YES;
                break;
            }
        }
        
        if (didAddObserver) {
            NSLog(@"BaymaxKVOProtector:%@ Has added Already", observer);
        } else {
            [infoArray addObject:kvoInfo];
        }
    } else {
        infoArray = [NSMutableArray new];
        [infoArray addObject:kvoInfo];
        kvoInfoMaps[keyPath] = infoArray;
        [self baymax_addObserver:kvoDelegate forKeyPath:keyPath options:options context:context];
    }
}

- (void)baymax_removeObserver:(NSObject *)observer
                   forKeyPath:(NSString *)keyPath
                      context:(void *)context {
    if (keyPath.length == 0 || !observer) {
        NSLog(@"Remove Observer Error:Check KVO KeyPath OR Observer");
        return;
    }
    
    CPKVODelegate *kvoDelegate = self.kvoDelegate;
    NSMutableDictionary *kvoInfoMaps = kvoDelegate.kvoInfoMaps;
    NSMutableArray *infoArray = kvoInfoMaps[keyPath];
    
    if (infoArray.count) {
        NSMutableArray *matchedInfos = [NSMutableArray new];
        
        for (CPKVOInfo *info in infoArray) {
            if (info.observer == observer || info.observer == nil) {
                [matchedInfos addObject:info];
            }
        }
        
        [infoArray removeObjectsInArray:matchedInfos];
        
        if (infoArray.count == 0) {
            [kvoInfoMaps removeObjectForKey:keyPath];
            [self baymax_removeObserver:kvoDelegate forKeyPath:keyPath context:context];
        }
    } else {
        NSLog(@"BaymaxKVOProtector:Obc has removed already!");
        [kvoInfoMaps removeObjectForKey:keyPath];
    }
}
```

```swift
//CPKVODelegate
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
```


#### 3、NSNotification类型crash防护
这部分很简单，不过iOS9之后的系统，已经不需要在`dealloc`中手动移除了。
> If your app targets iOS 9.0 and later or macOS 10.11 and later, you don't need to unregister an observer in its deallocation method. If your app targets earlier releases, be sure to invoke removeObserver:name:object: before observer or any object specified in addObserver:selector:name:object: is deallocated.

```swift
//NSObject (Baymax)
- (void)setDidRegisteredNotificationCenter:(BOOL)didRegisteredNotificationCenter {
    objc_setAssociatedObject(self, @selector(didRegisteredNotificationCenter), @(didRegisteredNotificationCenter), OBJC_ASSOCIATION_ASSIGN);
}

- (BOOL)didRegisteredNotificationCenter {
    NSNumber *result = objc_getAssociatedObject(self, _cmd);
    return result.boolValue;
}

- (void)baymax_dealloc {   
    if (self.didRegisteredNotificationCenter) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    
    [self baymax_dealloc];
}
```

```swift
- (void)baymax_addObserver:(id)observer
                  selector:(SEL)aSelector
                      name:(NSNotificationName)aName
                    object:(id)anObject {
    NSObject *obj = observer;
    obj.didRegisteredNotificationCenter = YES;
    [self baymax_addObserver:observer
                    selector:aSelector
                        name:aName
                      object:anObject];
}
```

#### 4、NSTimer类型crash防护
关于`NSTimer`强引用的问题，已经是业内的老问题了（Google下`iOS weak timer`，一大堆问题和答案），很多企业面试的时候也会问到。当然，相应地，解决方案也不是什么秘密。增加一个中间对象，解除强引用即可。网上也有很多开源的关于`weak timer`Repo，比如这个[HWWeakTimer](https://github.com/ChatGame/HWWeakTimer)。原文中处理的方法也是差不多一样的。

```swift
//NSTimer (Baymax)
+ (NSTimer *)baymax_scheduledTimerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(id)userInfo repeats:(BOOL)yesOrNo {
    if (yesOrNo) {
        CPStubTarget *stubTarget = [CPStubTarget new];
        stubTarget.weakTarget = aTarget;
        stubTarget.weakSelector = aSelector;
        stubTarget.weakTimer = [self baymax_scheduledTimerWithTimeInterval:ti target:stubTarget selector:@selector(fireProxyTimer:) userInfo:userInfo repeats:YES];
        return stubTarget.weakTimer;
    } else {
        return [self baymax_scheduledTimerWithTimeInterval:ti target:aTarget selector:aSelector userInfo:userInfo repeats:yesOrNo];
    }
}
```

```swift
//CPStubTarget
- (void)fireProxyTimer:(NSTimer *)userInfo {
    if (self.weakTarget) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.weakTarget performSelector:self.weakSelector withObject:userInfo];
#pragma clang diagnostic pop
    } else {
        [self.weakTimer invalidate];
        self.weakTimer = nil;
    }
}
```


#### 5、Container类型crash防护
这种集合类型的防护，逻辑比较简单，判断是否为`nil`、是否越界等就可以了。不过我不是很赞成用Hook的方式去做这种保护。原因是，这类集合在应用内使用的范围非常广，出错时会以`Exception`的形式抛出。或许会有一些代码依赖于这些`Exception`作处理。如果做全局的`Hook`不确定性太大。如果必须做这层保护的话，我可能会选择自己封装一个集合类型，内部持有一个系统集合对象，对接口调用处进行保护。当然，这样做代码量就会比较大了。不知道Baymax做这部分防护的时候，是怎么考虑的？


光这种类型空着，似乎不是那么好，也顺手写下吧。可能需要注意的是，OC里`NSArray`等这种集合类型的特殊性。这牵涉到`类簇`的概念。详见苹果官方文档[ClassClusters](https://developer.apple.com/library/ios/documentation/general/conceptual/CocoaEncyclopedia/ClassClusters/ClassClusters.html)，或者孙源的这篇[从NSArray看类簇](http://blog.sunnyxx.com/2014/12/18/class-cluster/)。


```swift
//NSArray (Baymax)
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [objc_getClass("__NSArray0") swizzleInstanceMethodWithOriginSel:@selector(objectAtIndex:) swizzledSel:@selector(baymax_empty_objectAtIndex:)];
        
        [objc_getClass("__NSSingleObjectArrayI") swizzleInstanceMethodWithOriginSel:@selector(objectAtIndex:) swizzledSel:@selector(baymax_singel_objectAtIndex:)];

        [objc_getClass("__NSArrayI") swizzleInstanceMethodWithOriginSel:@selector(objectAtIndex:) swizzledSel:@selector(baymax_objectAtIndex:)];
    });
}

- (id)baymax_empty_objectAtIndex:(NSUInteger)index {
    NSLog(@"BaymaxProtector:Out Of Bounds");
    return nil;
}

- (id)baymax_singel_objectAtIndex:(NSUInteger)index {
    if (index > 0) {
        NSLog(@"BaymaxProtector:Out Of Bounds");
    }
    
    return [self baymax_singel_objectAtIndex:0];
}

- (id)baymax_objectAtIndex:(NSUInteger)index {
    if (index < self.count) {
        return [self baymax_objectAtIndex:index];
    } else {
        NSLog(@"BaymaxProtector:Out Of Bounds");
        return nil;
    }
}
```
#### 6、NSString类型crash防护
同上，为了避免空着。。这两部分主要是体力活，简单实现一个来填空。

```swift
// NSString (Baymax)
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleInstanceMethodWithOriginSel:@selector(substringFromIndex:) swizzledSel:@selector(baymax_substringFromIndex:)];
    });
}

- (NSString *)baymax_substringFromIndex:(NSUInteger)from {
    if (from < self.length) {
        return [self baymax_substringFromIndex:from];
    } else {
        NSLog(@"BaymaxProtector:Out Of Length");
        return self;
    }
}
```
#### 7、野指针类型crash防护
个人感觉这部分是最有意思的。下周末再写。
