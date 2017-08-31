//
//  CTFrameParserConfig.h
//  CTTest
//
//  Created by chiery on 2016/8/17.
//  Copyright © 2016年 My-Zone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CTFrameParserConfig : NSObject

@property (nonatomic, strong) UIFont  *font;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, assign) BOOL    needBorder;
@property (nonatomic, assign) CGFloat borderWidth;
@property (nonatomic, assign) UIColor *borderColor;
@property (nonatomic, assign) CGFloat borderCornerRadius;
@property (nonatomic, assign) CGFloat borderHorizonSpacing;
@property (nonatomic, assign) CGFloat borderVerticalSpacing;
@property (nonatomic, assign) CGFloat lineHeight;

@end
