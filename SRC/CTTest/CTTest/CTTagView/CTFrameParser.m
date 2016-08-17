//
//  CTFrameParser.m
//  CTTest
//
//  Created by chiery on 2016/8/17.
//  Copyright © 2016年 My-Zone. All rights reserved.
//

#import "CTFrameParser.h"

@implementation CTFrameParser

+ (NSDictionary *)attributesWithConfig:(CTFrameParserConfig *)config {
    return @{
             NSForegroundColorAttributeName:config.textColor,
             NSFontAttributeName:config.font,
             @"CTAttributedStringNeedBorder":@(config.needBorder),
             @"CTAttributedStringBorderWidth":@(config.borderWidth),
             @"CTAttributedStringBorderColor":config.borderColor,
             @"CTAttributedStringBorderCornerRadius":@(config.borderCornerRadius),
             @"CTAttributedStringBorderHorizonSpacing":@(config.borderHorizonSpacing),
             @"CTAttributedStringBorderVerticalSpacing":@(config.borderVerticalSpacing)
             };
}


+ (CTFrameParserConfig *)configWithAttributes:(NSDictionary *)dictionary {
    CTFrameParserConfig *config = [CTFrameParserConfig new];
    if (dictionary) {
        if (dictionary[@"NSColor"]) config.textColor = dictionary[@"NSColor"];
        if (dictionary[@"NSFont"]) config.font = dictionary[@"NSFont"];
        if (dictionary[@"CTAttributedStringNeedBorder"]) config.needBorder = [dictionary[@"CTAttributedStringNeedBorder"] boolValue];
        if (dictionary[@"CTAttributedStringBorderWidth"]) config.borderWidth = [dictionary[@"CTAttributedStringBorderWidth"] floatValue];
        if (dictionary[@"CTAttributedStringBorderColor"]) config.borderColor = dictionary[@"CTAttributedStringBorderColor"];
        if (dictionary[@"CTAttributedStringBorderCornerRadius"]) config.borderCornerRadius = [dictionary[@"CTAttributedStringBorderCornerRadius"] floatValue];
        if (dictionary[@"CTAttributedStringBorderHorizonSpacing"]) config.borderHorizonSpacing = [dictionary[@"CTAttributedStringBorderHorizonSpacing"] floatValue];
        if (dictionary[@"CTAttributedStringBorderVerticalSpacing"]) config.borderVerticalSpacing = [dictionary[@"CTAttributedStringBorderVerticalSpacing"] floatValue];
    }
    return config;
}

@end
