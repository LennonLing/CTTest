//
//  ViewController.m
//  CTTest
//
//  Created by chiery on 2016/8/1.
//  Copyright © 2016年 My-Zone. All rights reserved.
//

#import "ViewController.h"
#import "CTDisplayView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self addDisplayView];
}

- (void)addDisplayView {
    CTDisplayView *displayView = [[CTDisplayView alloc] initWithFrame:CGRectMake(100, 20, CGRectGetWidth(self.view.bounds) - 40, CGRectGetHeight(self.view.bounds) - 200)];
    displayView.center = self.view.center;
    displayView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:displayView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
