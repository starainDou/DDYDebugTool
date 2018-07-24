#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSInteger, DDYDebugToolType) {
    DDYDebugToolTypeFPS    = 1 << 0,
    DDYDebugToolTypeCPU    = 1 << 1,
    DDYDebugToolTypeMemory = 1 << 2,
    DDYDebugToolTypeAll    = DDYDebugToolTypeFPS | DDYDebugToolTypeCPU | DDYDebugToolTypeMemory,
};

@interface DDYDebugTool : NSObject

/** 单例对象 */
+ (instancetype)sharedManager;

/** 展示信息 */
- (void)showWithType:(DDYDebugToolType)type;

@end
