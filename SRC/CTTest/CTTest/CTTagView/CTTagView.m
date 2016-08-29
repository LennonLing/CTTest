//
//  CTDisplayView.m
//  CTTest
//
//  Created by chiery on 2016/8/1.
//  Copyright © 2016年 My-Zone. All rights reserved.
//

#import "CTTagView.h"
#import <CoreText/CoreText.h>
#import "CTTagViewModel.h"
#import "CTFrameParserConfig.h"

const NSString * CTAttributedStringNeedBorder = @"CTAttributedStringNeedBorder";
const NSString * CTAttributedStringBorderWidth = @"CTAttributedStringBorderWidth";
const NSString * CTAttributedStringBorderColor = @"CTAttributedStringBorderColor";
const NSString * CTAttributedStringBorderCornerRadius = @"CTAttributedStringBorderCornerRadius";
const NSString * CTAttributedStringBorderHorizonSpacing = @"CTAttributedStringBorderHorizonSpacing";
const NSString * CTAttributedStringBorderVerticalSpacing = @"CTAttributedStringBorderVerticalSpacing";


@interface CTTagView ()
@property (nonatomic, strong) CTTagViewModel *model;
@end


@implementation CTTagView

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    
    // load model
    self.model = [[CTTagViewModel alloc] initWithAttributedString:self.attributedText andBounds:self.bounds];
    
    // 从这里获取当前View的size 组装对应的model
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    // 步骤 1  生成当前的环境
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // 步骤 2  转换坐标系
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    // 步骤 3  生成绘制文字的path
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, self.bounds);
    
    for (NSInteger i = 0; i < self.model.frameRefArray.count; i++) {
        CTFrameRef frame = (__bridge CTFrameRef)(self.model.frameRefArray[i]);
        CTFrameParserConfig *config = self.model.frameArray[i];
        
        // 需要边框的才会绘制边框
        if (config.needBorder) {
            CGPathRef path = (CGPathRef)CTFrameGetPath(frame);
            CGRect pathRect = CGPathGetPathBoundingBox(path);
            UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(pathRect, -config.borderHorizonSpacing, -config.borderVerticalSpacing) cornerRadius:config.borderCornerRadius];
            [config.borderColor set];
            bezierPath.lineWidth = config.borderWidth;
            [bezierPath stroke];
        }
        
        CTFrameDraw(frame, context);
    }
}



@end
