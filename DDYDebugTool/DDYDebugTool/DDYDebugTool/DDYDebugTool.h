#import <Foundation/Foundation.h>

@interface DDYDebugTool : NSObject
/*** 单例对象 */
+ (instancetype)sharedManager;
/** 展示信息 */
- (void)showInfo:(BOOL)show;

@end
