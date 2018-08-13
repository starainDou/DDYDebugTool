#import "ViewController.h"
#import "DDYDebugTool.h"
#import <objc/runtime.h>

@interface ViewController ()


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *takeButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setTitle:@"show" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [button setBackgroundColor:[UIColor lightGrayColor]];
        [button addTarget:self action:@selector(handleClick:) forControlEvents:UIControlEventTouchUpInside];
        [button setFrame:CGRectMake(0, 100, 120, 30)];
        button;
    });
    [self.view addSubview:takeButton];
    // 显示调试工具视图
    [DDYDebugTool show:YES];
}

- (void)handleClick:(UIButton *)sender {
    // 在屏幕上要显示的内容
    [DDYDebugTool log:@"点击按钮"];
    // 捕获系统打印转存到文件
    [DDYDebugTool handleSystemLog];
}

@end
