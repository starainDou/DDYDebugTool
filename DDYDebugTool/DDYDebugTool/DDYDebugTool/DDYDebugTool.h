#import <Foundation/Foundation.h>

@interface DDYDebugTool : NSObject
/** 展示信息 */
+ (void)show:(BOOL)show;

/** 展示日志 */
+ (void)log:(NSString *)log;

/** 重定向NSLog到文件 系统将不再打印 所以慎用 */
+ (void)handleSystemLog;

@end
