#import "DDYFPSMonitor.h"
#import <UIKit/UIKit.h>
// self甚至weakSelf在这里都无法避免循环引用
@interface DDYWeakProxy : NSProxy

@property (nonatomic, weak, readonly) id target;

- (instancetype)initWithTarget:(id)target;
+ (instancetype)proxyWithTarget:(id)target;

@end

@implementation DDYWeakProxy

- (instancetype)initWithTarget:(id)target {
    _target = target;
    return self;
}

#pragma mark - 类方法
+ (instancetype)proxyWithTarget:(id)target {
    return [[DDYWeakProxy alloc] initWithTarget:target];
}

#pragma mark - 私有方法
- (id)forwardingTargetForSelector:(SEL)selector {
    return _target;
}

#pragma mark - 重写方法
// 重写NSProxy如下两个方法，在处理消息转发时，将消息转发给真正的Target处理
- (void)forwardInvocation:(NSInvocation *)invocation {
    void *null = NULL;
    [invocation setReturnValue:&null];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    return [NSObject instanceMethodSignatureForSelector:@selector(init)];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return [_target respondsToSelector:aSelector];
}

- (BOOL)isEqual:(id)object {
    return [_target isEqual:object];
}

- (NSUInteger)hash {
    return [_target hash];
}

- (Class)superclass {
    return [_target superclass];
}

- (Class)class {
    return [_target class];
}

- (BOOL)isKindOfClass:(Class)aClass {
    return [_target isKindOfClass:aClass];
}

- (BOOL)isMemberOfClass:(Class)aClass {
    return [_target isMemberOfClass:aClass];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    return [_target conformsToProtocol:aProtocol];
}

- (BOOL)isProxy {
    return YES;
}

- (NSString *)description {
    return [_target description];
}

- (NSString *)debugDescription {
    return [_target debugDescription];
}

@end

@implementation DDYFPSMonitor
{
    CADisplayLink *_displayLink;
    NSUInteger _count;
    NSTimeInterval _lastTime;
}

#pragma mark 开始监测
- (void)startMonitor {
    // 如果直接用 self 甚至 weakSelf ，都会有循环引用问题
    // 将 timer 的 target 从 self ，变成了中间人 NSProxy
    // timer 调用 target 的 selector 时，会被 NSProxy 内部转调用 self 的 selector
    [self stopMonitor];
    _displayLink = [CADisplayLink displayLinkWithTarget:[DDYWeakProxy proxyWithTarget:self] selector:@selector(tick:)];
    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

#pragma mark 结束监测
- (void)stopMonitor {
    [_displayLink invalidate];
    _displayLink = nil;
}

- (void)tick:(CADisplayLink *)link {
    if (_lastTime == 0) {
        _lastTime = link.timestamp;
        return;
    }
    _count++;
    NSTimeInterval delta = link.timestamp - _lastTime;
    if (delta < 1) return;
    _lastTime = link.timestamp;
    float fps = _count / delta;
    _count = 0;
    if (_monitorBlock) {
        _monitorBlock(fps);
    }
}

- (void)dealloc {
    [self stopMonitor];
}

@end
