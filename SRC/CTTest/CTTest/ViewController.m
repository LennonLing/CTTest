//
//  ViewController.m
//  CTTest
//
//  Created by chiery on 2016/8/1.
//  Copyright © 2016年 My-Zone. All rights reserved.
//

#import "ViewController.h"
#import "CTTagView.h"
#import "CTFrameParser.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet CTTagView *tagView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self addDisplayView];
}

- (void)addDisplayView {
    
    NSString *content = @"阅读分为四个阶段：基础阅读，检视阅读，分析阅读，主题阅读，经典的图书有经典的理由\n，《如何阅读一本书》的阅读分类方法第一次让我看到自己停留在什么阅读层次，该如何提高。这本书详细给出了每种阅读方法的进行步骤，\n以及不同种类的书籍要如何阅读，可以说是研究阅读方法的基础教材。看了这本书之后再看其他《越读者》、《王者速读法》等图书强化速读\n、主题阅读等，阅读方法有了显著的提高。";
    CTFrameParserConfig *config = [CTFrameParserConfig new];
    
    // 这里设置当前文字中最大的宽度和高度的间隔，避免文字压线
    config.borderHorizonSpacing = 0;
    config.borderVerticalSpacing = 0;
    
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:content attributes:[CTFrameParser attributesWithConfig:config]];
    [attributedString addAttributes:@{
                                      NSForegroundColorAttributeName:[UIColor blackColor],
                                      NSFontAttributeName:[UIFont systemFontOfSize:10]
                                      } range:NSMakeRange(0, attributedString.length)];
    [attributedString addAttributes:@{
                                      NSForegroundColorAttributeName:[UIColor redColor],
                                      NSFontAttributeName:[UIFont systemFontOfSize:10],
                                      CTAttributedStringNeedBorder:@(YES),
                                      CTAttributedStringBorderHorizonSpacing:@(1),
                                      CTAttributedStringBorderVerticalSpacing:@(1)
                                      } range:NSMakeRange(20, 1)];
    
    [attributedString addAttributes:@{
                                      NSForegroundColorAttributeName:[UIColor redColor],
                                      NSFontAttributeName:[UIFont systemFontOfSize:12],
                                      CTAttributedStringNeedBorder:@(YES)
                                      } range:NSMakeRange(50, 6)];
    
    [attributedString addAttributes:@{
                                      NSForegroundColorAttributeName:[UIColor redColor],
                                      NSFontAttributeName:[UIFont systemFontOfSize:20],
                                      CTAttributedStringNeedBorder:@(YES),
                                      CTAttributedStringBorderWidth:@(1),
                                      CTAttributedStringBorderColor:[UIColor greenColor],
                                      CTAttributedStringBorderCornerRadius:@(0),
                                      CTAttributedStringBorderHorizonSpacing:@(2),
                                      CTAttributedStringBorderVerticalSpacing:@(2),
                                      } range:NSMakeRange(70, 4)];
    
    [attributedString addAttributes:@{
                                      NSForegroundColorAttributeName:[UIColor redColor],
                                      NSFontAttributeName:[UIFont systemFontOfSize:28],
                                      CTAttributedStringNeedBorder:@(YES),
                                      CTAttributedStringBorderWidth:@(1),
                                      CTAttributedStringBorderColor:[UIColor greenColor],
                                      CTAttributedStringBorderCornerRadius:@(0),
                                      CTAttributedStringBorderHorizonSpacing:@(1),
                                      CTAttributedStringBorderVerticalSpacing:@(2),
                                      } range:NSMakeRange(75, 2)];
    
    [attributedString addAttributes:@{
                                      NSForegroundColorAttributeName:[UIColor redColor],
                                      NSFontAttributeName:[UIFont systemFontOfSize:8],
                                      CTAttributedStringNeedBorder:@(YES),
                                      CTAttributedStringBorderWidth:@(1),
                                      CTAttributedStringBorderColor:[UIColor yellowColor],
                                      CTAttributedStringBorderCornerRadius:@(0),
                                      CTAttributedStringBorderHorizonSpacing:@(1),
                                      CTAttributedStringBorderVerticalSpacing:@(1),
                                      } range:NSMakeRange(90, 5)];
    
    [attributedString addAttributes:@{
                                      NSForegroundColorAttributeName:[UIColor redColor],
                                      NSFontAttributeName:[UIFont systemFontOfSize:8],
                                      CTAttributedStringNeedBorder:@(YES),
                                      CTAttributedStringBorderWidth:@(1),
                                      CTAttributedStringBorderColor:[UIColor yellowColor],
                                      CTAttributedStringBorderCornerRadius:@(0),
                                      CTAttributedStringBorderHorizonSpacing:@(2),
                                      CTAttributedStringBorderVerticalSpacing:@(2),
                                      } range:NSMakeRange(98, 5)];
    
    [attributedString addAttributes:@{
                                      NSForegroundColorAttributeName:[UIColor redColor],
                                      NSFontAttributeName:[UIFont systemFontOfSize:6],
                                      CTAttributedStringNeedBorder:@(YES),
                                      CTAttributedStringBorderWidth:@(1),
                                      CTAttributedStringBorderColor:[UIColor yellowColor],
                                      CTAttributedStringBorderCornerRadius:@(0),
                                      CTAttributedStringBorderHorizonSpacing:@(2),
                                      CTAttributedStringBorderVerticalSpacing:@(2),
                                      } range:NSMakeRange(104, 3)];
    self.tagView.attributedText = attributedString;
    self.tagView.center = self.view.center;
    self.tagView.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];
    //    [self.view addSubview:displayView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
