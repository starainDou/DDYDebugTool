#import "DDYDebugTool.h"
#import "DDYSystemInfo.h" // https://github.com/starainDou/DDYDeviceInfo
#import "DDYFPSMonitor.h"
#import <UIKit/UIKit.h>

#ifndef DDYStatusBarH
#define DDYStatusBarH [[UIApplication sharedApplication] statusBarFrame].size.height
#endif

#ifndef DDYScreenW
#define DDYScreenW [UIScreen mainScreen].bounds.size.width
#endif

#ifndef DDYScreenH
#define DDYScreenH [UIScreen mainScreen].bounds.size.height
#endif

#ifndef DDYDebugToolLabelH
#define DDYDebugToolLabelH 20
#endif

@interface DDYDebugTool ()

@property (nonatomic, strong) DDYFPSMonitor *monitor;
@property (nonatomic, strong) UILabel *labelFPS;
@property (nonatomic, strong) UILabel *labelCPU;
@property (nonatomic, strong) UILabel *labelMemory;
@property (nonatomic, strong) UIWindow *alertWindow;

@end

@implementation DDYDebugTool

- (UIWindow *)alertWindow {
    if (!_alertWindow) {
        _alertWindow = [[UIWindow alloc] init];
        _alertWindow.frame = CGRectMake(0, DDYStatusBarH-DDYDebugToolLabelH, DDYScreenW, DDYDebugToolLabelH);
        _alertWindow.backgroundColor = [UIColor clearColor];
        _alertWindow.windowLevel = UIWindowLevelAlert;
        _alertWindow.rootViewController = [[UIViewController alloc] init];
        _alertWindow.hidden = NO;
    }
    return _alertWindow;
}

- (UILabel *)labelFPS {
    if (!_labelFPS) {
        _labelFPS = [self labelX:0];
    }
    return _labelFPS;
}

- (UILabel *)labelCPU {
    if (!_labelCPU) {
        _labelCPU = [self labelX:DDYScreenW/3.];
    }
    return _labelCPU;
}

- (UILabel *)labelMemory {
    if (!_labelMemory) {
        _labelMemory = [self labelX:DDYScreenW*2./3.];
    }
    return _labelMemory;
}

- (UILabel *)labelX:(CGFloat)x {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, DDYScreenW/3., DDYDebugToolLabelH)];
    [label setFont:[UIFont systemFontOfSize:15]];
    [label setTextColor:[UIColor greenColor]];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.7]];
    [self.alertWindow addSubview:label];
    return label;
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
- (void)showWithType:(DDYDebugToolType)type {
    
    __weak __typeof (self)weakSelf = self;
    [self.monitor setMonitorBlock:^(float fps) {
        __strong __typeof (weakSelf)strongSelf = weakSelf;
        if (type & DDYDebugToolTypeFPS) {
            [strongSelf handleFPS:fps];
        }
        if (type & DDYDebugToolTypeCPU) {
            [strongSelf handleCPU:[DDYSystemInfo ddy_CPUUsage]];
        }
        if (type & DDYDebugToolTypeMemory) {
            [strongSelf handleMemory:[DDYSystemInfo ddy_MemoryUsage]];
        }
    }];
    [self.monitor startMonitor];
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

@end


