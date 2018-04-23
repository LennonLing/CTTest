//
//  CTFrameParserConfig.m
//  CTTest
//
//  Created by chiery on 2016/8/17.
//  Copyright © 2016年 My-Zone. All rights reserved.
//

#import "CTFrameParserConfig.h"

@implementation CTFrameParserConfig

- (instancetype)init
{
    self = [super init];
    if (self) {
        _textColor = [UIColor redColor];
        _font = [UIFont systemFontOfSize:13];
        _needBorder = NO;
        _borderWidth = 1/[[UIScreen mainScreen] scale];
        _borderColor = [UIColor redColor];
        _borderCornerRadius = 3;
        _borderHorizonSpacing = 0;
        _borderVerticalSpacing = 0;
    }
    return self;
}

- (void)setBorderWidth:(CGFloat)borderWidth {
    NSAssert(borderWidth < 3, @"建议不要将边框的宽度设置的过大！");
    _borderWidth = borderWidth;
}

- (void)setBorderCornerRadius:(CGFloat)borderCornerRadius {
    NSAssert(borderCornerRadius < 6, @"建议不要讲边框的圆角半径设置的过大！");
    _borderCornerRadius = borderCornerRadius;
}

- (void)setBorderHorizonSpacing:(CGFloat)borderHorizonSpacing {
    NSAssert(borderHorizonSpacing < 6, @"建议不要将水平间隔设置的过大！");
    _borderHorizonSpacing = borderHorizonSpacing;
}

- (void)setBorderVerticalSpacing:(CGFloat)borderVerticalSpacing {
    NSAssert(borderVerticalSpacing < 6, @"建议不要讲垂直间隔设置的过大！");
    _borderVerticalSpacing = borderVerticalSpacing;
}

@end
