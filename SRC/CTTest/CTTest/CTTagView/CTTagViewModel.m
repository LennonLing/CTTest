//
//  CTDisplayViewModel.m
//  CTTest
//
//  Created by chiery on 2016/8/15.
//  Copyright © 2016年 My-Zone. All rights reserved.
//

#import "CTTagViewModel.h"
#import <CoreText/CoreText.h>
#import "NSAttributedString+Line.h"
#import "CTFrameParser.h"
#import "CTShortFrameModel.h"

/**
 *  单独的attributedString在当前行中的长度。
 */
typedef NS_ENUM(NSInteger, CTAttributedStringLengthType) {
    /**
     *  小于当前行的长度
     */
    CTAttributedStringLengthTypeDefault,
    /**
     *  大于等于当前行的长度
     */
    CTAttributedStringLengthTypeGreatOrEqualThanLine,
};

/**
 *  当前attributedString是否需要加上边框
 */
typedef NS_ENUM(NSInteger, CTAttributedStringNeedBorder) {
    /**
     *  不需要加边框
     */
    CTAttributedStringNeedBorderDefault,
    /**
     *  需要加上边框
     */
    CTAttributedStringNeedBorderYes
};

/**
 *  当前attributedString在当前行排版的位置
 */
typedef NS_ENUM(NSInteger, CTAttributedStringJoin) {
    /**
     *  默认从行首开始排版
     */
    CTAttributedStringJoinDefault,
    /**
     *  从行中间开始排版
     */
    CTAttributedStringJoinMiddle
};

/**
 *  由一个一个短小的attributedString填充的碎片行，是否被填充满
 */
typedef NS_ENUM(NSInteger, CTPieceLineCompleted) {
    /**
     *  没有被填充满
     */
    CTPieceLineCompletedDefault,
    /**
     *  充满
     */
    CTPieceLineCompletedDone
};

static CGFloat CTTagViewXStart = 1;
static CGFloat CTTageViewYStart = 3;

@interface CTTagViewModel ()
@property (nonatomic) CGRect contextBounds;
@property (nonatomic) CGFloat xStart;
@property (nonatomic) CGFloat yStart;
@property (nonatomic) CTFramesetterRef framesetter;

@property (nonatomic, strong) NSAttributedString *attributedString;
@property (nonatomic, strong, readwrite) NSArray *frameRefArray;
@property (nonatomic, strong) NSMutableArray *frameRefMutableArray;
@property (nonatomic, strong, readwrite) NSArray *frameArray;
@property (nonatomic, strong) NSMutableArray *frameMutableArray;
@property (nonatomic, strong) NSMutableArray *tempShortFrameMutableArray;
@end

@implementation CTTagViewModel

- (void)dealloc {
    CFRelease(_framesetter);
}

- (instancetype)initWithAttributedString:(NSAttributedString *)attributedString andBounds:(CGRect)bounds {
    self = [super init];
    if (self) {
        NSAssert(attributedString, @"富文本为空");
        NSAssert(bounds.size.width > 0 && bounds.size.height > 0, @"文本区域复制存在问题");
        
        if (attributedString && bounds.size.width > 0 && bounds.size.height > 0) {
            [self setAttributedString:attributedString];
            [self setContextBounds:bounds];
            [self buildFrameRef];
            [self analyseAttributedStringInfo];
            [self addEndAttributedString];
        }
    }
    return self;
}

- (void)buildFrameRef {
    self.framesetter = CTFramesetterCreateWithAttributedString(
                                                          (CFAttributedStringRef)self.attributedString);
}

- (void)analyseAttributedStringInfo {
    __weak typeof(self) weakSelf = self;
    [self.attributedString enumerateAttributesInRange:NSMakeRange(0, self.attributedString.length)
                                              options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                                           usingBlock:^(NSDictionary<NSString *,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
                                               __strong typeof(weakSelf) strongSelf = weakSelf;
                                               if (strongSelf) [strongSelf createLineRefWithRange:range config:[CTFrameParser configWithAttributes:attrs]];
                                           }];
}

- (void)addEndAttributedString{
    [self addPieceLineRef];
}

- (void)createLineRefWithRange:(NSRange)range config:(CTFrameParserConfig *)config{
    // 如果range.length == 0说明该段属性下的文字已经绘制完全了递归的时候使用
    if (range.length == 0) return;
    // 根据range那个attributedString
    NSAttributedString *attributedString = [self.attributedString attributedSubstringFromRange:range];
    // 计算绘制的高度是否超出给定的高度
    if ([self greatThanBoundsHeight:attributedString config:config]) {self.yStart = CGFLOAT_MAX; return;}
    
    // 计算当前文字的拼接节点是在行开始还是在行中间
    switch ([self attributedStringJoin]) {
        // 行开始的处理
        case CTAttributedStringJoinDefault:
            // 当前需要绘制的文字的长度类型
            switch ([self attributedStringLengthType:attributedString config:config]) {
                // 长度小于当前行的情况，将当前信息收集起来，x游标向后移动
                case CTAttributedStringLengthTypeDefault:
                    [self addShortFrameModel:attributedString config:config range:range];
                    [self.frameMutableArray addObject:config];
                    [self setXStart:self.xStart + attributedString.width + 2*config.borderHorizonSpacing];
                    break;
                // 长度大于当前行的情况，绘制此文字
                case CTAttributedStringLengthTypeGreatOrEqualThanLine:
                    [self addCompletedLineRef:range config:config];
                    break;
            }
            break;
        // 行中间的处理
        case CTAttributedStringJoinMiddle:
            //
            switch ([self pieceLineCompleted:attributedString config:config]) {
                // 没有被充满,将当前信息收集起来，x游标向后移动
                case CTPieceLineCompletedDefault:
                    [self addShortFrameModel:attributedString config:config range:range];
                    [self.frameMutableArray addObject:config];
                    [self setXStart:self.xStart + attributedString.width + 2*config.borderHorizonSpacing];
                    break;
                // 已经被充满
                case CTPieceLineCompletedDone:
                    // 计算当前绘制的文字是否需要加边框
                    switch ([self attributedStringNeedFrame:config]) {
                        // 不需要加上边框
                        case CTAttributedStringNeedBorderDefault:
                            [self addBreakAttributesStringWithRange:range config:config];
                            break;
                        // 需要加边框，将之前行文字数组中的文字绘制，x游标指向0，本次文字做递归处理
                        case CTAttributedStringNeedBorderYes:
                            [self addPieceLineRef];
                            [self setXStart:CTTagViewXStart];
                            [self createLineRefWithRange:range config:config];
                            break;
                    }
                    break;
            }
            break;
    }
}

#pragma mark - 辅助函数
- (void)collectFrameAndModelWithAttibutedString:(NSAttributedString *)attributedString rectInset:(CGRect)rectInset range:(NSRange)range {
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, rectInset);
    CTFrameRef frame = CTFramesetterCreateFrame(self.framesetter, CFRangeMake(range.location, range.length), path, NULL);
    [self.frameRefMutableArray addObject:(__bridge id _Nonnull)(frame)];
    CFRelease(frame);
    CFRelease(path);
}

#pragma mark - 整理行环境
- (void)addCompletedLineRef:(NSRange)range config:(CTFrameParserConfig *)config {
    NSAttributedString *attributedString = [self.attributedString attributedSubstringFromRange:range];
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGRect tempRect = CGRectInset([self convertRect:CGRectMake(self.xStart, self.yStart, CGRectGetWidth(self.contextBounds), attributedString.height + 2 * config.borderVerticalSpacing)], config.borderHorizonSpacing, config.borderVerticalSpacing);
    CGPathAddRect(path, NULL, tempRect);
    CTFrameRef frame = CTFramesetterCreateFrame(self.framesetter, CFRangeMake(range.location, range.length), path, NULL);
    
    // 从这里开始将之前的文本截断，绘制可以绘制的range
    CFRange frameRange = CTFrameGetVisibleStringRange(frame);
    
    // 将能绘制的丢到shortFrame中去
    NSRange canDrawRange = NSMakeRange(range.location, frameRange.length);
    NSAttributedString *canDrawAttributedString = [self.attributedString attributedSubstringFromRange:canDrawRange];
    CGRect canDrawRect = CGRectInset([self convertRect:CGRectMake(self.xStart, self.yStart, CGRectGetWidth(self.contextBounds), canDrawAttributedString.height + 2 * config.borderVerticalSpacing)], config.borderHorizonSpacing, config.borderVerticalSpacing);
    [self collectFrameAndModelWithAttibutedString:canDrawAttributedString rectInset:canDrawRect range:canDrawRange];
    [self.frameMutableArray addObject:config];
    
    // 多余的丢到下一行去绘制
    self.xStart = CTTagViewXStart;
    self.yStart += (canDrawAttributedString.height + 2 * config.borderVerticalSpacing);
    
    [self createLineRefWithRange:NSMakeRange(frameRange.length + range.location, range.length - frameRange.length) config:config];
    CFRelease(frame);
    CFRelease(path);
}

- (void)addPieceLineRef {
    if (self.tempShortFrameMutableArray.count == 0) return;
    [self setXStart:CTTagViewXStart];
    [self createShortLineFrameRef];
    [self setYStart:self.yStart + [self maxLineHeight]];
    [self.tempShortFrameMutableArray removeAllObjects];
}

- (void)createShortLineFrameRef {
    
    // 这里对最大行高做一下处理，从最大行高计算出除去行间距的具体的绘制的高度
    CGFloat drawHeight = [self maxLineHeightWithoutLeadingLanguage];
    
    for (CTShortFrameModel *model in self.tempShortFrameMutableArray) {
        
        // 将每个CTRun的自己的高度
        CGFloat runHeight = model.attributedString.lineHeight;
        
        // 为了是绘制的中心线对齐，y锚点应该在的高度
        CGFloat yStart = self.yStart + drawHeight - ((drawHeight - runHeight) / 2.0 + runHeight);
        CGRect rectInset = [self convertRect:CGRectMake(self.xStart, yStart, model.attributedString.width + 2*model.config.borderHorizonSpacing, model.attributedString.height + 2 * model.config.borderVerticalSpacing)];
        
        CGRect tempRect = CGRectInset(rectInset, model.config.borderHorizonSpacing, model.config.borderVerticalSpacing);
        [self collectFrameAndModelWithAttibutedString:model.attributedString rectInset:tempRect range:model.range];
        self.xStart += (model.attributedString.width + 2*model.config.borderHorizonSpacing);
    }
}

- (void)addBreakAttributesStringWithRange:(NSRange)range config:(CTFrameParserConfig *)config {
    self.xStart = CTTagViewXStart;
    NSAttributedString *attributedString = [self.attributedString attributedSubstringFromRange:range];

    CGFloat maxLineHeight = [self maxLineHeight]>(attributedString.height + 2*config.borderVerticalSpacing)?[self maxLineHeight]:(attributedString.height + 2*config.borderVerticalSpacing);
    CGFloat drawHeight = [self maxLineHeightWithoutLeadingLanguage];
    [self createShortLineFrameRef];
    [self.tempShortFrameMutableArray removeAllObjects];
    
    CGFloat runHeight = attributedString.lineHeight;
    CGFloat yStart  = self.yStart + drawHeight - ((drawHeight - runHeight) / 2.0 + runHeight);
    
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGRect tempRect = CGRectInset([self convertRect:CGRectMake(self.xStart, yStart, CGRectGetWidth(self.contextBounds) - self.xStart, (attributedString.height + 2*config.borderVerticalSpacing))], config.borderHorizonSpacing, config.borderVerticalSpacing);
    CGPathAddRect(path, NULL, tempRect);
    CTFrameRef frame = CTFramesetterCreateFrame(self.framesetter, CFRangeMake(range.location, range.length), path, NULL);
    CFRange frameRange = CTFrameGetVisibleStringRange(frame);

    // 将能绘制的先绘制出来
    NSRange canDrawRange = NSMakeRange(range.location, frameRange.length);
    NSAttributedString *canDrawAttributedString = [self.attributedString attributedSubstringFromRange:canDrawRange];
    CGRect canDrawRect = CGRectInset([self convertRect:CGRectMake(self.xStart, yStart, CGRectGetWidth(self.contextBounds) - self.xStart, canDrawAttributedString.height + 2 * config.borderVerticalSpacing)], config.borderHorizonSpacing, config.borderVerticalSpacing);
    [self collectFrameAndModelWithAttibutedString:canDrawAttributedString rectInset:canDrawRect range:canDrawRange];
    [self.frameMutableArray addObject:config];
    
    // 多余的丢到下一行去绘制
    self.xStart = CTTagViewXStart;
    
    self.yStart += maxLineHeight;
    
    [self createLineRefWithRange:NSMakeRange(frameRange.length + range.location, range.length - frameRange.length) config:config];
    CFRelease(frame);
    CFRelease(path);
}

- (void)addShortFrameModel:(NSAttributedString *)attributedString config:(CTFrameParserConfig *)config range:(NSRange)range {
    CTShortFrameModel *model = [CTShortFrameModel new];
    model.attributedString = attributedString;
    model.config = config;
    model.range = range;
    [self.tempShortFrameMutableArray addObject:model];
}

- (CGFloat)maxLineHeightWithoutLeadingLanguage {
    CGFloat maxHeight = 0;
    for (CTShortFrameModel *model in self.tempShortFrameMutableArray) {
        if (model.attributedString.lineHeight > maxHeight)
            maxHeight = model.attributedString.lineHeight;
    }
    return maxHeight;
}

- (CGFloat)maxLineHeight {
    CGFloat maxHeight = 0;
    for (CTShortFrameModel *model in self.tempShortFrameMutableArray) {
        if ((model.attributedString.height + 2*model.config.borderVerticalSpacing) > maxHeight)
            maxHeight = (model.attributedString.height + 2*model.config.borderVerticalSpacing);
    }
    return maxHeight;
}

- (CGRect)convertRect:(CGRect)rect {
    return CGRectMake(rect.origin.x, CGRectGetHeight(self.contextBounds) - rect.origin.y - rect.size.height, CGRectGetWidth(rect), CGRectGetHeight(rect));
}

#pragma mark - 检测当拼接的状态

- (BOOL)greatThanBoundsHeight:(NSAttributedString *)attributedString config:(CTFrameParserConfig *)config{
    if ((self.yStart + attributedString.height + 2*config.borderVerticalSpacing) > CGRectGetHeight(self.contextBounds))
        return YES;
    return NO;
}

- (CTAttributedStringLengthType)attributedStringLengthType:(NSAttributedString *)attibutedString config:(CTFrameParserConfig *)config {
    if ((attibutedString.width + 2*config.borderHorizonSpacing) > CGRectGetWidth(self.contextBounds))
        return CTAttributedStringLengthTypeGreatOrEqualThanLine;
    return CTAttributedStringLengthTypeDefault;
}

- (CTAttributedStringNeedBorder)attributedStringNeedFrame:(CTFrameParserConfig *)config {
    if (config.needBorder) return CTAttributedStringNeedBorderYes;
    return CTAttributedStringNeedBorderDefault;
}

- (CTPieceLineCompleted)pieceLineCompleted:(NSAttributedString *)attributedString config:(CTFrameParserConfig *)config {
    if ((self.xStart + attributedString.width + 2*config.borderHorizonSpacing) > CGRectGetWidth(self.contextBounds))
        return CTPieceLineCompletedDone;
    return CTPieceLineCompletedDefault;
}

- (CTAttributedStringJoin)attributedStringJoin {
    if (self.xStart > CTTagViewXStart)
        return CTAttributedStringJoinMiddle;
    return CTAttributedStringJoinDefault;
}

#pragma mark - init property
- (NSMutableArray *)frameRefMutableArray {
    if (!_frameRefMutableArray) {
        _frameRefMutableArray = [NSMutableArray new];
    }
    return _frameRefMutableArray;
}

- (NSArray *)frameRefArray {
    if (!_frameRefArray) {
        _frameRefArray = [self.frameRefMutableArray copy];
    }
    return _frameRefArray;
}

- (NSArray *)frameArray {
    if (!_frameArray) {
        _frameArray = [self.frameMutableArray copy];
    }
    return _frameArray;
}

- (NSMutableArray *)frameMutableArray {
    if (!_frameMutableArray) {
        _frameMutableArray = [NSMutableArray new];
    }
    return _frameMutableArray;
}

- (NSMutableArray *)tempShortFrameMutableArray {
    if (!_tempShortFrameMutableArray) {
        _tempShortFrameMutableArray = [NSMutableArray new];
    }
    return _tempShortFrameMutableArray;
}

@end
