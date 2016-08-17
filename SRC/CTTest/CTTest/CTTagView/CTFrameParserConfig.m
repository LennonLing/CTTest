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
        _borderHorizonSpacing = 2;
        _borderVerticalSpacing = 2;
    }
    return self;
}

@end
