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
//    CTDisplayView *displayView = [[CTDisplayView alloc] initWithFrame:CGRectMake(100, 20, CGRectGetWidth(self.view.bounds) - 40, CGRectGetHeight(self.view.bounds) - 200)];
    CTDisplayView *displayView = [CTDisplayView new];
    displayView.frame =CGRectMake(100, 20, CGRectGetWidth(self.view.bounds) - 40, CGRectGetHeight(self.view.bounds) - 200);
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:@"阅读分为四个阶段：基础阅读，检视阅读，分析阅读，主题阅读，经典的图书有经典的理由，《如何阅读一本书》的阅读分类方法第一次让我看到自己停留在什么阅读层次，该如何提高。这本书详细给出了每种阅读方法的进行步骤，以及不同种类的书籍要如何阅读，可以说是研究阅读方法的基础教材。看了这本书之后再看其他《越读者》、《王者速读法》等图书强化速读、主题阅读等，阅读方法有了显著的提高。"];
    [attributedString addAttributes:@{
                                      NSForegroundColorAttributeName:[UIColor blackColor],
                                      NSFontAttributeName:[UIFont systemFontOfSize:12]
                                      } range:NSMakeRange(0, attributedString.length)];
    [attributedString addAttributes:@{
                                      NSForegroundColorAttributeName:[UIColor redColor],
                                      NSFontAttributeName:[UIFont systemFontOfSize:12],
                                      CTAttributedStringNeedBorder:@(YES)
                                      } range:NSMakeRange(20, 12)];
    
    [attributedString addAttributes:@{
                                      NSForegroundColorAttributeName:[UIColor redColor],
                                      NSFontAttributeName:[UIFont systemFontOfSize:30],
                                      CTAttributedStringNeedBorder:@(YES)
                                      } range:NSMakeRange(50, 12)];
    displayView.attributedText = attributedString;
    displayView.center = self.view.center;
    displayView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:displayView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
