#import "DDYDebugTool.h"
#import "DDYSystemInfo.h" // https://github.com/starainDou/DDYDeviceInfo
#import "DDYFPSMonitor.h"
#import <UIKit/UIKit.h>

static inline CGFloat screenW() { return [UIScreen mainScreen].bounds.size.width; }
static inline CGFloat screenH() { return [UIScreen mainScreen].bounds.size.height; }
static inline CGFloat startY() { return [DDYSystemInfo deviceType]==IPhone_X ? 74 : 30; }
static inline CGFloat endY() { return [DDYSystemInfo deviceType]==IPhone_X ? (screenH()-34) : screenH(); }
static inline CGFloat backViewH(BOOL expand) { return expand ? (endY()-startY())/2. : 60; }
static inline CGFloat topViewH() { return 40;}
static inline NSInteger maxCount() { return 100;}

@interface DDYAlertWindow : UIWindow
+ (instancetype)alertWindow;
@end

@implementation DDYAlertWindow

+ (instancetype)alertWindow {
    return [[self alloc] initWithFrame:[UIScreen mainScreen].bounds];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setBackgroundColor:[UIColor clearColor]];
        [self setWindowLevel:UIWindowLevelAlert];
    }
    return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if (view == self) {
        return nil;
    }
    return view;
}

@end


@interface DDYDebugTool ()<CAAnimationDelegate>
/** 用来控制拖动时不能点击 */
@property (nonatomic, assign) BOOL isExpand;
/** 可以拖动的视图 */
@property (nonatomic, strong) UIView *backView;
/** 动画遮罩 */
@property (nonatomic, strong) CAShapeLayer *maskLayer;
/** 显示FPS */
@property (nonatomic, strong) UILabel *labelFPS;
/** 显示CPU使用情况 */
@property (nonatomic, strong) UILabel *labelCPU;
/** 显示内存使用情况 */
@property (nonatomic, strong) UILabel *labelMemory;
/** 显示日志textView */
@property (nonatomic, strong) UITextView *logTextView;
/** FPS探测器 */
@property (nonatomic, strong) DDYFPSMonitor *monitor;
/** alert级别window */
@property (nonatomic, strong) DDYAlertWindow *alertWindow;
/** 日志数组 */
@property (nonatomic, strong) NSMutableArray *logArray;

@end

@implementation DDYDebugTool

#pragma mark - lazy getter
- (UIWindow *)alertWindow {
    if (!_alertWindow) {
        _alertWindow = [DDYAlertWindow alertWindow];
        [_alertWindow addSubview:self.backView];
    }
    return _alertWindow;
}

#pragma mark 可拖动按钮 getter
- (UIView *)backView {
    if (!_backView) {
        _backView = [[UIView alloc] initWithFrame:CGRectMake(0, startY(), backViewH(NO), backViewH(NO))];
        [_backView.layer addSublayer:self.maskLayer];
        [_backView addSubview:self.labelFPS];
        [_backView addSubview:self.labelCPU];
        [_backView addSubview:self.labelMemory];
        [_backView addSubview:self.logTextView];
        [_backView setClipsToBounds:YES];
        [_backView addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)]];
        [_backView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)]];
    }
    return _backView;
}

- (CAShapeLayer *)maskLayer {
    if (!_maskLayer) {
        _maskLayer = [CAShapeLayer layer];
        _maskLayer.fillColor = [UIColor colorWithWhite:0 alpha:0.7].CGColor;
        _maskLayer.strokeColor = [UIColor greenColor].CGColor;
        _maskLayer.lineWidth = 0.5;
        _maskLayer.path = [self smallPath].CGPath;
    }
    return _maskLayer;
}

#pragma mark FPS getter
- (UILabel *)labelFPS {
    if (!_labelFPS) {
        _labelFPS = [self labelIndex:0];
        _labelFPS.frame = CGRectMake(0, 0, backViewH(NO), backViewH(NO));
    }
    return _labelFPS;
}

#pragma mark CPU getter
- (UILabel *)labelCPU {
    if (!_labelCPU) {
        _labelCPU = [self labelIndex:1];
    }
    return _labelCPU;
}

#pragma mark Memory getter
- (UILabel *)labelMemory {
    if (!_labelMemory) {
        _labelMemory = [self labelIndex:2];
    }
    return _labelMemory;
}

- (UILabel *)labelIndex:(NSInteger)index {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(index * screenW() / 3., 0, screenW()/3., topViewH())];
    [label setFont:[UIFont systemFontOfSize:15]];
    [label setTextColor:[UIColor greenColor]];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setBackgroundColor:[UIColor clearColor]];
    [label setNumberOfLines:0];
    return label;
}

- (UITextView *)logTextView {
    if (!_logTextView) {
        _logTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, topViewH(), screenW(), backViewH(YES)-topViewH())];
        [_logTextView setShowsVerticalScrollIndicator:NO];
        [_logTextView setShowsHorizontalScrollIndicator:NO];
        [_logTextView setBounces:NO];
        [_logTextView setEditable:NO];
        [_logTextView setFont:[UIFont fontWithName:@"Courier" size:12]];
        [_logTextView setTextColor:[UIColor greenColor]];
        [_logTextView setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.2]];
        [_logTextView.layoutManager setAllowsNonContiguousLayout:NO];
    }
    return _logTextView;
}

- (NSMutableArray *)logArray {
    if (!_logArray) {
        _logArray = [NSMutableArray arrayWithCapacity:maxCount()];
    }
    return _logArray;
}

- (DDYFPSMonitor *)monitor {
    if (!_monitor) {
        _monitor = [[DDYFPSMonitor alloc] init];
    }
    return _monitor;
}

- (void)setIsExpand:(BOOL)isExpand {
    _isExpand = isExpand;
    self.labelCPU.hidden = !isExpand;
    self.labelMemory.hidden = !isExpand;
    self.logTextView.hidden = !isExpand;
}

#pragma mark - 单例对象

static DDYDebugTool *_instance;

+ (instancetype)sharedManager {
    return [[self alloc] init];
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}

- (id)copyWithZone:(NSZone *)zone {
    return _instance;
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    return _instance;
}

+ (void)show:(BOOL)show {
    [[DDYDebugTool sharedManager] showInfo:show];
}

#pragma mark - 展示信息
- (void)showInfo:(BOOL)show {
#if TARGET_IPHONE_SIMULATOR
    NSLog(@"SIMULATOR DEVICE");
#else
    [self.alertWindow setHidden:!show];
    [self setIsExpand:!show];
    if (show) {
        __weak __typeof (self)weakSelf = self;
        [self.monitor setMonitorBlock:^(float fps) {
            __strong __typeof (weakSelf)strongSelf = weakSelf;
            [strongSelf handleFPS:fps];
            [strongSelf handleCPU:[DDYSystemInfo ddy_CPUUsage]];
            [strongSelf handleMemory:[DDYSystemInfo ddy_MemoryUsage]];
        }];
        [self.monitor startMonitor];
    } else {
        [self.monitor stopMonitor];
    }
#endif
}

#pragma mark 重定向NSLog到文件
+ (void)handleSystemLog {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [dateFormatter setDateFormat:@"yyyy_MM_dd_HH_mm_ss"];
    NSString *timeString = [dateFormatter stringFromDate:[NSDate date]];
    
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *logPath = [NSString stringWithFormat:@"%@/DDYDebugToolLog/%@.log", documentPath, timeString];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:logPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:logPath error:nil];
    }
    
    freopen([logPath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stdout); // c printf
    freopen([logPath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr); // oc NSLog
}

#pragma mark  展示日志
+ (void)log:(NSString *)log {
    [[DDYDebugTool sharedManager] showLog:log];
}

- (void)showLog:(NSString *)log {
    if (log && log.length) {
        if (self.logArray.count > (maxCount()-1)) {
            [self.logArray removeObjectAtIndex:0];
        }
        NSLog(@"%@", log);
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [dateFormatter setDateFormat:@"HH:mm:ss:SSS"];
        NSString *timeString = [dateFormatter stringFromDate:[NSDate date]];
        
        [self.logArray addObject:[NSString stringWithFormat:@"%@ %@ %drow %@\n", timeString, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, log]];
    }
    NSString *showLog = [NSString string];
    for (NSString *tempLog in self.logArray) {
        showLog = [showLog stringByAppendingString:tempLog];
    }
    if (showLog && showLog.length) {
        [self.logTextView setText:showLog];
        [self.logTextView scrollRangeToVisible:NSMakeRange(showLog.length - 1, 1)];
    }
}

#pragma mark FPS文字处理
- (void)handleFPS:(float)fps {
    NSString *string = [NSString stringWithFormat:@"%@%.2f", @"FPS:", fps];
    NSRange range1 = NSMakeRange(0, string.length);
    NSRange range2 = [string rangeOfString:@"FPS:" options:NSBackwardsSearch];
    NSMutableAttributedString *attributedStr = [[NSMutableAttributedString alloc] initWithString:string];
    [attributedStr addAttribute:NSForegroundColorAttributeName value:[UIColor greenColor] range:range1];
    [attributedStr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:14] range:range1];
    [attributedStr addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:range2];
    self.labelFPS.attributedText = attributedStr;
}

#pragma mark CPU文字处理
- (void)handleCPU:(float)cpu {
    NSString *string = [NSString stringWithFormat:@"%@%.2f%%", @"CPU:", cpu];
    NSRange range1 = NSMakeRange(0, string.length);
    NSRange range2 = [string rangeOfString:@"CPU:" options:NSBackwardsSearch];
    NSMutableAttributedString *attributedStr = [[NSMutableAttributedString alloc] initWithString:string];
    [attributedStr addAttribute:NSForegroundColorAttributeName value:[UIColor greenColor] range:range1];
    [attributedStr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:14] range:range1];
    [attributedStr addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:range2];
    self.labelCPU.attributedText = attributedStr;
}

#pragma mark Memory文字处理
- (void)handleMemory:(float)memory {
    NSString *string = [NSString stringWithFormat:@"%@%.2fM", @"Memory:", memory];
    NSRange range1 = NSMakeRange(0, string.length);
    NSRange range2 = [string rangeOfString:@"Memory:" options:NSBackwardsSearch];
    NSMutableAttributedString *attributedStr = [[NSMutableAttributedString alloc] initWithString:string];
    [attributedStr addAttribute:NSForegroundColorAttributeName value:[UIColor greenColor] range:range1];
    [attributedStr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:14] range:range1];
    [attributedStr addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:range2];
    self.labelMemory.attributedText = attributedStr;
}

- (UIBezierPath *)smallPath {
    return [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, backViewH(NO), backViewH(NO))];
}

- (UIBezierPath *)bigPath {
    CGFloat diameter = sqrt(screenW()*screenW() + backViewH(YES)*backViewH(YES));
//    return [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, screenW(), backViewH(YES))];
    return [UIBezierPath bezierPathWithOvalInRect:CGRectMake((screenW()-diameter)/2., (backViewH(YES)-diameter)/2., diameter, diameter)];
}

- (void)handleTap:(UITapGestureRecognizer *)recognizer {
    self.isExpand = !self.isExpand;

    CABasicAnimation *maskLayerAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
    maskLayerAnimation.fromValue = (__bridge id) (self.isExpand ? [self smallPath].CGPath : [self bigPath].CGPath);
    maskLayerAnimation.toValue = (__bridge id) (self.isExpand ? [self bigPath].CGPath : [self smallPath].CGPath);
    maskLayerAnimation.duration = 0.3;
    maskLayerAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    maskLayerAnimation.delegate = self;
    maskLayerAnimation.removedOnCompletion = NO; // 动画结束后不移除
    maskLayerAnimation.fillMode = kCAFillModeForwards;//这两句的效果是让动画结束后不会回到原处，必须加
    [self.maskLayer addAnimation:maskLayerAnimation forKey:@"path"];
    
    [UIView animateWithDuration:0.3 animations:^{
        if (self.isExpand) {
            self.backView.frame = CGRectMake(0, self.backView.frame.origin.y, screenW(), backViewH(YES));
            self.labelFPS.frame = CGRectMake(0, 0, screenW()/3., topViewH());
        } else {
            self.backView.frame = CGRectMake(0, self.backView.frame.origin.y, 60, 60);
            self.labelFPS.frame = CGRectMake(0, 0, backViewH(NO), backViewH(NO));
        }
    }];
    [self layoutSubviews];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {

}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        NSLog(@"FlyElephant---视图拖动开始");
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint location = [recognizer locationInView:self.alertWindow];
        CGPoint translation = [recognizer translationInView:self.alertWindow];
        NSLog(@"当前视图在View的位置:%@----平移位置:%@",NSStringFromCGPoint(location), NSStringFromCGPoint(translation));
        recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x,recognizer.view.center.y + translation.y);
        [recognizer setTranslation:CGPointZero inView:self.alertWindow];
    } else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
        NSLog(@"FlyElephant---视图拖动结束");
        [self layoutSubviews];
    }
}

- (void)layoutSubviews {
    
    if (self.backView.frame.origin.x < 0) {
        CGRect frame = self.backView.frame;
        frame.origin.x = 0;
        self.backView.frame = frame;
    }
    if ((self.backView.frame.origin.x + self.backView.frame.size.width) > screenW()) {
        CGRect frame = self.backView.frame;
        frame.origin.x = screenW() - frame.size.width;
        self.backView.frame = frame;
    }
    if (self.backView.frame.origin.y < startY()) {
        CGRect frame = self.backView.frame;
        frame.origin.y = startY();
        self.backView.frame = frame;
    }
    if ((self.backView.frame.origin.y + self.backView.frame.size.height) > endY()) {
        CGRect frame = self.backView.frame;
        frame.origin.y = endY() - frame.size.height;
        self.backView.frame = frame;
    }
}

@end


