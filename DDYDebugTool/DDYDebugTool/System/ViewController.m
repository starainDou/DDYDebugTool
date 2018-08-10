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
    
    [[DDYDebugTool sharedManager] showInfo:YES];
}

- (void)handleClick:(UIButton *)sender {
    
    for (int i = 0; i < 100; i++) {
        NSLog(@"%d", i);
    }
}

@end
