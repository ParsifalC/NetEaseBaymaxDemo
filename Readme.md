## TODO
- [x] Unit Test
- [ ] Bad Access 防护
- [ ] UI Not On Main Thread 防护
- [ ] Refactor Code

## 扯扯闲话
网易移动端团队前阵子在他们Blog发布了一篇文章，是关于他们自主研发的Crash自防护机制——[大白健康系统--iOS APP运行时Crash自动修复系统](https://neyoufan.github.io/2017/01/13/ios/BayMax_HTSafetyGuard/)”。看过原文后，觉得挺有意思的，是一个不错的Runtime实践用例。这个Repo是根据原文提供方案仿写的小Demo，仅做讨论研究讨论使用，期待官方早日完成测试开源SDK，学习下源码。**这里不讨论这种防护是否有必要，仅当学习练手之用。**
**最后感谢网易TZY的交流解惑，通过交流技术认识到新朋友是很快乐的。**

## 仿写过程及疑问
#### Unrecognized Selector类型crash防护
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


1）文中提到`注意如果对象的类本身如果重写了forwardInvocation方法的话，就不应该对forwardingTargetForSelector进行重写了，否则会影响到该类型的对象原本的消息转发流程。`这部分似乎并不能在这里通过代码判断。`[self respondsToSelector:@selector(forwardInvocation:)]`返回的始终是YES。因为`NSObject`默认的`forward​Invocation:​`实现是调用`does​Not​Recognize​Selector:​`。Baymax目前是通过什么方式来排除这种情况的呢？


>**Answer**： 目前我是通过判断对象是否有重写`forwardInvocation：`这个方法来判断是否需要进入forwardingTargetForSelector这个流程的，具体方法如下:


```objc
+ (BOOL)isClassMethodOverWrite:(Class)clazz selector:(SEL)sel{
    Method selfMethod = class_getClassMethod(clazz, sel);
    Method superMethod = class_getClassMethod(class_getSuperclass(clazz), sel);
    return selfMethod != superMethod;
}
```
>**Update**：这是很好的一个trick，直接判断父类获取的Method是否等于从当前类获取的Method即可。Method是一个`struct`的指针，有三个成员变量：`objc_method`、`method_types`和`method_imp`。子类若复写了父类的方法，IMP会改变为子类的IMP，Method的指针地址就相应地变了。

2）关于桩类对象的释放问题，通过手动`objc_registerClassPair:`创建的类对象，只能通过`objc_disposeClassPair:`手动释放。这里的类对象，是否直到程序结束由系统回收，运行过程中不做释放呢（虽然占据内存也不是很大）？或者再复写`dealloc`方法，从这里做回收（这样似乎也没有必要，如果出现多次crash，就会有反复创建和销毁操作）？
> **Answer**：这里我不是很明白为什么一定要通过objc_registerClassPair：这个方法来创建类的对象，我这边仅仅是通过alloc init来创建对象的。ARC自己会搞定一切
> **Update**：通过上面的回答可以猜测到，Baymax目前的桩类应该是编译期就建立了的，也就是直接继承于`NSObject`创建StubProxy类，然后在做转发的时候，直接往这个类添加Method，归根到底是一样的。它的这个类对象也是不会被释放的，区别只在于是否动态地创建这个类。我之前的考虑是，如果一次crash都没有发生，我就不生成这个桩类。

3）Swizzle`forwardingTargetForSelector`这个方法后，从Log上看，在App启动后，会有多次的转发，我猜测这个现象与上面那个问题一致，这是系统的一些私有类，产生的异常系统自己处理掉了，那么这种情况Baymax目前是怎么处理的（而且Swizzle后会造成XCTest无法正常进行测试）？Log如下：


```ruby
2017-03-15 18:55:37.168 NetEaseBaymaxDemo[77401:4583918] catch unrecognize selector crash getServerAnswerForQuestion:reply:
2017-03-15 18:55:37.648 NetEaseBaymaxDemo[77401:4583918] catch unrecognize selector crash startArbitrationWithExpectedState:hostingPIDs:withSuppression:onConnected:
2017-03-15 18:55:37.678 NetEaseBaymaxDemo[77401:4583918] catch unrecognize selector crash _setTextColor:
2017-03-15 18:55:37.678 NetEaseBaymaxDemo[77401:4583918] catch unrecognize selector crash _setMagnifierLineColor:
2017-03-15 18:55:37.678 NetEaseBaymaxDemo[77401:4583918] catch unrecognize selector crash _setTextColor:
2017-03-15 18:55:37.679 NetEaseBaymaxDemo[77401:4583918] catch unrecognize selector crash _setMagnifierLineColor:
2017-03-15 18:55:38.003 NetEaseBaymaxDemo[77401:4583918] catch unrecognize selector crash setPresentationContextPrefersCancelActionShown:
```
> **Answer**：这里的forwardingTargetForSelector，我仅仅会专门针对开发者自己创建的类来进行防护。同时还建立了一个黑 白名单的机制，来自定义自己想参加防护的对象。 比如UIView 这个类，虽然是系统的类，但是我可以通过将其加入白名单的机制，从而对其和其子类进行防护。通过以下方法来判断是否是自定义的类：

```objc
+ (BOOL)isMainBundleClass:(Class)clazz{
    return clazz && [[NSBundle bundleForClass:clazz] isEqual:[NSBundle mainBundle]];
}
```

> **Update**：又是一个很妙的trick。首先`MainBundle`的目录是存储Target各资源、framework和代码文件，默认新增的文件都是存在这个目录下。但系统的类文件则是在系统`Library`路径下。通过这样比较`Bundle`就可以过滤掉系统类了。


#### KVO类型crash防护
关于KVO部分，Facebook之前有出过小工具，思路与这个有点类似，都是通过中间层来转发消息，[KVOController](https://github.com/facebook/KVOController)。根据原文方案，这里也是通过增加`CPKVODelegate`作代理，转发消息实现。为每个被观察对象添加一个代理，以这个代理作为实际的观察者，所有的消息都会发往这个观察者然后再处理派发。主要针对以下三种crash情况：


- 移除一个非观察者：`Cannot remove an observer <...> for the key path "keypath" from <...> because it is not registered as an observer.`
- 观察者释放后，未从观察者KVO中移除：`message sent to deallocated instance`
- 被观察者释放后，未移除其所有观察者：`deallocated while key value observers were still registered with it.`


这一部分我的疑问是：

1）由于Hook的是`NSObject`这个基类，系统内部的一些实现也是会使用KVO。在写这个Demo的时候，我也发现，系统在启动阶段也会调用几次的`addObserver..`方法。那么我的疑问是，这样做转发后，在实际运用中，如果大范围的使用KVO，损失的效率会明显吗？希望到时候能分享下实践过程遇到的坑。

> **Answer**：首先上面说了我们可以只针对自己创建的类进行防护。其次我个人认为我们KVO的处理是将KVO的关系进行了一层swizzle转发，其中效率损失的地方在于创建类kvodelegate这个类作为原本类的属性，因为对于效率的损失还ok。不过我自己还并没有专门针对KVO的性能问题进行过测试，所以也不能保证KVO处理方式的性能一定没有问题哈。如果可以的话，是否可以帮助测试一下～

> **Update**：我的做法是给每个被观察者都添加一份代理，目前还不清楚Baymax里面是做一个单例代理还是和我的方案一样。不过目前的主流方案都是差不多的做法，损失的性能都在额外添加的代理这个上面。可以抽时间测试下性能。


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


#### NSNotification类型crash防护
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

#### NSTimer类型crash防护
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


#### Container类型crash防护
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
#### NSString类型crash防护
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
#### 野指针类型crash防护
个人感觉这部分是最有意思的。下周末再写。

## 参考资料
- [我是本文的源码](https://github.com/ParsifalC/NetEaseBaymaxDemo)
- [大白健康系统--iOS APP运行时Crash自动修复系统](https://neyoufan.github.io/2017/01/13/ios/BayMax_HTSafetyGuard/)