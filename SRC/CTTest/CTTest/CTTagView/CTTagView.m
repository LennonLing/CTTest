//
//  CTDisplayView.m
//  CTTest
//
//  Created by chiery on 2016/8/1.
//  Copyright © 2016年 My-Zone. All rights reserved.
//

#import "CTTagView.h"
#import <CoreText/CoreText.h>
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

- (instancetype)initWithModel:(CTTagViewModel *)model {
    if (self = [super init]) {
        self.model = model;
    }
    return self;
}

- (void)layoutSubviews {
    
    [super layoutSubviews];
    
    // 如果在布局之前model已经创建完成，用已经创建的model来布局
    if (!self.model) {
        // 从这里开始布局 来支持autoLayout
        // load model
        self.model = [[CTTagViewModel alloc] initWithAttributedString:self.attributedText andBounds:CGRectGetWidth(self.bounds)];
    }
    
    // 这里拿到了model的高度
    [self invalidateIntrinsicContentSize];
    // 从这里获取当前View的size 组装对应的model
    [self setNeedsDisplay];
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(CGRectGetWidth(self.bounds), ceil(self.model.contextHeight));
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
    CGPathRelease(path);
    
    for (NSInteger i = 0; i < self.model.frameRefArray.count; i++) {
        CTFrameRef frame = (__bridge CTFrameRef)(self.model.frameRefArray[i]);
        CTFrameParserConfig *config = self.model.frameArray[i];
        
        // 需要边框的才会绘制边框
        if (config.needBorder) {
            CGPathRef borderPath = (CGPathRef)CTFrameGetPath(frame);
            CGRect pathRect = CGPathGetPathBoundingBox(borderPath);
            
            // 在ios8之后的版本中行高提高了，这里需要增加额外的计算
            CGRect tempPathRect = CGRectMake(pathRect.origin.x, pathRect.origin.y + (pathRect.size.height - config.lineHeight), pathRect.size.width, config.lineHeight);
            CGRect rectInset = CGRectInset(tempPathRect, -config.borderHorizonSpacing, -config.borderVerticalSpacing);
            UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:rectInset cornerRadius:config.borderCornerRadius];
            [config.borderColor set];
            bezierPath.lineWidth = config.borderWidth;
            [bezierPath stroke];
        }
        
        CTFrameDraw(frame, context);
    }
}

@end
