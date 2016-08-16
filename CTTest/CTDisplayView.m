//
//  CTDisplayView.m
//  CTTest
//
//  Created by chiery on 2016/8/1.
//  Copyright © 2016年 My-Zone. All rights reserved.
//

#import "CTDisplayView.h"
#import <CoreText/CoreText.h>
#import "CTDisplayViewModel.h"

const NSString * CTAttributedStringNeedBorder = @"CTAttributedStringNeedBorder";
const NSString * CTAttributedStringBorderWidth = @"CTAttributedStringBorderWidth";
const NSString * CTAttributedStringBorderColor = @"CTAttributedStringBorderColor";
const NSString * CTAttributedStringBorderCornerRadius = @"CTAttributedStringBorderCornerRadius";

@interface CTDisplayView ()
@property (nonatomic, strong) CTDisplayViewModel *model;
@end


@implementation CTDisplayView

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    
    self.model = [[CTDisplayViewModel alloc] initWithAttributedString:self.attributedText andBounds:self.bounds];
    
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
        
        CGPathRef path = (CGPathRef)CTFrameGetPath(frame);
        CGRect pathRect = CGPathGetPathBoundingBox(path);
        UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(pathRect, -2, -3) cornerRadius:2];
        [[UIColor greenColor] set];
        bezierPath.lineWidth = 0.5f;
        [bezierPath stroke];
        
        CTFrameDraw(frame, context);
    }
}



@end
