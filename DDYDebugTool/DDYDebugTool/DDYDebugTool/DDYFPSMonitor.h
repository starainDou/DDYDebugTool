#import <Foundation/Foundation.h>

@interface DDYFPSMonitor : NSObject

@property (nonatomic, copy) void (^monitorBlock)(float fps);

/** 开始监测 */
- (void)startMonitor;

/** 结束监测 */
- (void)stopMonitor;

@end
