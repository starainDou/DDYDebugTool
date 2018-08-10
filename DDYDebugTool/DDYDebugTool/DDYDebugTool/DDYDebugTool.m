#import "DDYDebugTool.h"
#import "DDYSystemInfo.h" // https://github.com/starainDou/DDYDeviceInfo
#import "DDYFPSMonitor.h"
#import <UIKit/UIKit.h>

#define LogFileName @"DDYDebugToolLogger.log"

static inline CGFloat screenW() { return [UIScreen mainScreen].bounds.size.width; }
static inline CGFloat screenH() { return [UIScreen mainScreen].bounds.size.height; }
static inline CGFloat startY() { return [DDYSystemInfo deviceType]==IPhone_X ? 64 : 20; }
static inline CGFloat endY() { return [DDYSystemInfo deviceType]==IPhone_X ? (screenH()-34) : screenH(); }
static inline CGFloat viewH(BOOL expand) { return expand ? screenH()/2. : 20; }
static inline NSString *logPath() {
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *logPath = [documentPath stringByAppendingPathComponent:LogFileName];
    return logPath;
}

@interface DDYDebugTool ()
/** 用来控制拖动时不能点击 */
@property (nonatomic, assign) BOOL isExpand;
/** 可以拖动的视图 */
@property (nonatomic, strong) UIView *backView;
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
@property (nonatomic, strong) UIWindow *alertWindow;
/** 日志数组 */
@property (nonatomic, strong) NSMutableArray *logArray;

@end

@implementation DDYDebugTool

#pragma mark - lazy getter
- (UIWindow *)alertWindow {
    if (!_alertWindow) {
        _alertWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        [_alertWindow setBackgroundColor:[UIColor clearColor]];
        [_alertWindow setWindowLevel:UIWindowLevelAlert];
        [_alertWindow addSubview:self.backView];
    }
    return _alertWindow;
}

#pragma mark 可拖动按钮 getter
- (UIView *)backView {
    if (!_backView) {
        _backView = [[UIView alloc] initWithFrame:CGRectMake(0, startY(), screenW()/3., viewH(NO))];
        [_backView setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.7]];
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

#pragma mark FPS getter
- (UILabel *)labelFPS {
    if (!_labelFPS) {
        _labelFPS = [self labelIndex:0];
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
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(index * screenW() / 3., 0, screenW()/3., viewH(NO))];
    [label setFont:[UIFont systemFontOfSize:15]];
    [label setTextColor:[UIColor greenColor]];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setBackgroundColor:[UIColor clearColor]];
    return label;
}

- (UITextView *)logTextView {
    if (!_logTextView) {
        _logTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, viewH(NO), screenW(), viewH(YES)-viewH(NO))];
        [_logTextView setShowsVerticalScrollIndicator:NO];
        [_logTextView setShowsHorizontalScrollIndicator:NO];
        [_logTextView setBounces:NO];
        [_logTextView setEditable:NO];
        [_logTextView setFont:[UIFont systemFontOfSize:13.0]];
        [_logTextView setTextColor:[UIColor greenColor]];
        [_logTextView setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.2]];
    }
    return _logTextView;
}

- (NSMutableArray *)logArray {
    if (!_logArray) {
        _logArray = [NSMutableArray arrayWithCapacity:50];
    }
    return _logArray;
}

- (DDYFPSMonitor *)monitor {
    if (!_monitor) {
        _monitor = [[DDYFPSMonitor alloc] init];
    }
    return _monitor;
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

#pragma mark - 展示信息
- (void)showInfo:(BOOL)show {
#if TARGET_IPHONE_SIMULATOR
    NSLog(@"SIMULATOR DEVICE");
#else
    [self.alertWindow setHidden:!show];
    if (show) {
        __weak __typeof (self)weakSelf = self;
        [self.monitor setMonitorBlock:^(float fps) {
            __strong __typeof (weakSelf)strongSelf = weakSelf;
            [strongSelf handleFPS:fps];
            [strongSelf handleCPU:[DDYSystemInfo ddy_CPUUsage]];
            [strongSelf handleMemory:[DDYSystemInfo ddy_MemoryUsage]];
            [strongSelf loadLog];
        }];
        [self startSaveLog];
        [self.monitor startMonitor];
    } else {
        [self.monitor stopMonitor];
    }
#endif
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

#pragma mark 重定向NSLog到文件
- (void)startSaveLog {
    if ([[NSFileManager defaultManager] fileExistsAtPath:logPath()]) {
        [[NSFileManager defaultManager] removeItemAtPath:logPath() error:nil];
    }
    
    freopen([logPath() cStringUsingEncoding:NSASCIIStringEncoding], "a+", stdout); // c printf
    freopen([logPath() cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr); // oc NSLog
}

#pragma mark
- (void)loadLog {
    NSString *log = [NSString stringWithContentsOfFile:logPath() encoding:NSUTF8StringEncoding error:nil];
    if (log) {
        self.logTextView.text = log;
    }
}

- (void)handleTap:(UITapGestureRecognizer *)recognizer {
    if ((self.isExpand = !self.isExpand)) {
        [UIView animateWithDuration:0.3 animations:^{
            self.backView.frame = CGRectMake(0, self.backView.frame.origin.y, screenW(), viewH(YES));
        }];
    } else {
        [UIView animateWithDuration:0.3 animations:^{
            self.backView.frame = CGRectMake(0, self.backView.frame.origin.y, screenW()/3., viewH(NO));
        }];
    }
    [self layoutSubviews];
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


