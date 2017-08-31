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

static CGFloat CTTagViewXStart = 0;
//static CGFloat CTTageViewYStart = 3;

@interface CTRunRectModel : NSObject
@property (nonatomic)       CGRect rect;
@property (nonatomic)       NSRange range;
@property (nonatomic, strong) NSAttributedString *attributedString;
@end
@implementation CTRunRectModel
@end

@interface CTTagViewModel ()
@property (nonatomic) CGFloat contextWidth;
@property (nonatomic) CGFloat xStart;
@property (nonatomic) CGFloat yStart;
@property (nonatomic) NSInteger lineNumber;
@property (nonatomic) CTFramesetterRef framesetter;

@property (nonatomic, strong) NSAttributedString *attributedString;
@property (nonatomic, strong, readwrite) NSArray *frameRefArray;
@property (nonatomic, strong) NSMutableArray *frameRefMutableArray;
@property (nonatomic, strong, readwrite) NSArray *frameArray;
@property (nonatomic, assign, readwrite) CGFloat contextHeight;
@property (nonatomic, strong) NSMutableArray *frameMutableArray;
@property (nonatomic, strong) NSMutableArray *tempShortFrameMutableArray;
@property (nonatomic, strong) NSMutableArray *runRectModelArray;
@end

@implementation CTTagViewModel

- (instancetype)initWithAttributedString:(NSAttributedString *)attributedString andBounds:(CGFloat)contextWidth {
    self = [super init];
    if (self) {
        if (attributedString && contextWidth > 0) {
            [self setAttributedString:attributedString];
            [self setContextWidth:contextWidth];
            [self buildFrameRef];
            [self analyseAttributedStringInfo];
            [self addEndAttributedString];
            [self getFrameRef];
        }
    }
    return self;
}

- (void)buildFrameRef {
    _framesetter = CTFramesetterCreateWithAttributedString(
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
    
    // 这里添加config高度
    config.lineHeight = attributedString.lineHeight;
    
    // TODO: 暂时没有做行数的限制，这个可以在后来的现象中增加
    // 计算绘制的高度是否超出给定的高度
//    if ([self greatThanBoundsHeight:attributedString config:config]) {self.yStart = CGFLOAT_MAX; return;}
    
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

- (void)addRunRectModelByRect:(CGRect)rect
                        range:(NSRange)range
             attributedString:(NSAttributedString *)string {
    CTRunRectModel *model = [CTRunRectModel new];
    model.rect = rect;
    model.attributedString = string;
    model.range = range;
    [self.runRectModelArray addObject:model];
}

- (void)collectFrameAndModelWithAttibutedString:(NSAttributedString *)attributedString rectInset:(CGRect)rectInset range:(NSRange)range {
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, rectInset);
    CTFrameRef frame = CTFramesetterCreateFrame(self.framesetter, CFRangeMake(range.location, range.length), path, NULL);
    [self.frameRefMutableArray addObject:(__bridge id _Nonnull)(frame)];
    CFRelease(frame);
    CFRelease(path);
}

- (void)getFrameRef {
    // 在这个阶段已经知道了当前的高度是多少了
    self.contextHeight = self.yStart;
    // 遍历暂存的rect数组
    for (CTRunRectModel *rectModel in self.runRectModelArray) {
        CGRect rectInset = [self convertRect:rectModel.rect];
        [self collectFrameAndModelWithAttibutedString:rectModel.attributedString rectInset:rectInset range:rectModel.range];
    }
}

#pragma mark - 整理行环境
- (void)addCompletedLineRef:(NSRange)range config:(CTFrameParserConfig *)config {
    NSAttributedString *attributedString = [self.attributedString attributedSubstringFromRange:range];
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGRect tempRect = CGRectMake(self.xStart + config.borderHorizonSpacing, self.yStart + config.borderVerticalSpacing, self.contextWidth - 2 * config.borderHorizonSpacing, attributedString.height);
    CGPathAddRect(path, NULL, tempRect);
    CTFrameRef frame = CTFramesetterCreateFrame(self.framesetter, CFRangeMake(range.location, range.length), path, NULL);
    
    // 从这里开始将之前的文本截断，绘制可以绘制的range
    CFRange frameRange = CTFrameGetVisibleStringRange(frame);
    
    // 将能绘制的丢到shortFrame中去
    NSRange canDrawRange = NSMakeRange(range.location, frameRange.length);
    NSAttributedString *canDrawAttributedString = [self.attributedString attributedSubstringFromRange:canDrawRange];
    [self addRunRectModelByRect:CGRectMake(self.xStart + config.borderHorizonSpacing, self.yStart + config.borderVerticalSpacing, self.contextWidth - 2 * config.borderHorizonSpacing, canDrawAttributedString.height) range:canDrawRange attributedString:canDrawAttributedString];
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
    [self createShortLineFrameRef:[self maxLineHeightWithoutLeadingLanguage] maxVerticalHeight:[self maxLineVerticalHeight]];
    [self setYStart:self.yStart + [self maxLineHeight]];
    [self.tempShortFrameMutableArray removeAllObjects];
}

- (void)createShortLineFrameRef:(CGFloat)drawHeight maxVerticalHeight:(CGFloat)maxVerticalHeight {
    // 这里对最大行高做一下处理，从最大行高计算出除去行间距的具体的绘制的高度
//    CGFloat maxLeadingHeight = [self maxLeadingHeight];
    for (CTShortFrameModel *model in self.tempShortFrameMutableArray) {
        // 将每个CTRun的自己的高度
        CGFloat runHeight = model.attributedString.lineHeight;
        
        // 为了是绘制的中心线对齐，y锚点应该在的高度
        
        CGFloat yStart = self.yStart + drawHeight + 2 * maxVerticalHeight - (((drawHeight + 2 * maxVerticalHeight) - (runHeight + 2 * model.config.borderVerticalSpacing)) / 2.0 + (runHeight + model.config.borderVerticalSpacing));

        
//        CGFloat yStart = self.yStart + drawHeight + 2 * maxVerticalHeight - (((drawHeight + 2 * maxVerticalHeight) - (runHeight + 2 * model.config.borderVerticalSpacing)) / 2.0 + (runHeight + model.config.borderVerticalSpacing)) + maxLeadingHeight - (model.attributedString.height - model.attributedString.lineHeight);
        CGRect rectInset = CGRectMake(self.xStart + model.config.borderHorizonSpacing, yStart, model.attributedString.width, model.attributedString.height);
        
        [self addRunRectModelByRect:rectInset range:model.range attributedString:model.attributedString];
        self.xStart += (model.attributedString.width + 2*model.config.borderHorizonSpacing);
    }
}

- (void)addBreakAttributesStringWithRange:(NSRange)range config:(CTFrameParserConfig *)config {
    self.xStart = CTTagViewXStart;
    NSAttributedString *attributedString = [self.attributedString attributedSubstringFromRange:range];
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGFloat xStart = [self shortLineWidth];
    CGRect tempRect = CGRectMake(xStart + config.borderHorizonSpacing, self.yStart, self.contextWidth - (xStart + 2 * config.borderHorizonSpacing), attributedString.height);
    CGPathAddRect(path, NULL, tempRect);
    CTFrameRef frame = CTFramesetterCreateFrame(self.framesetter, CFRangeMake(range.location, range.length), path, NULL);
    CFRange frameRange = CTFrameGetVisibleStringRange(frame);
    CFRelease(frame);
    CFRelease(path);

    // 将能绘制的先绘制出来
    NSRange canDrawRange = NSMakeRange(range.location, frameRange.length);
    NSAttributedString *canDrawAttributedString = [self.attributedString attributedSubstringFromRange:canDrawRange];
    
    [self addShortFrameModel:canDrawAttributedString config:config range:canDrawRange];
    [self.frameMutableArray addObject:config];
    [self createShortLineFrameRef:[self maxLineHeightWithoutLeadingLanguage] maxVerticalHeight:[self maxLineVerticalHeight]];
    
    // 多余的丢到下一行去绘制
    self.xStart = CTTagViewXStart;
    self.yStart += [self maxLineHeight];
    
    [self.tempShortFrameMutableArray removeAllObjects];
    [self createLineRefWithRange:NSMakeRange(frameRange.length + range.location, range.length - frameRange.length) config:config];
    
}

- (void)addShortFrameModel:(NSAttributedString *)attributedString config:(CTFrameParserConfig *)config range:(NSRange)range {
    CTShortFrameModel *model = [CTShortFrameModel new];
    model.attributedString = attributedString;
    model.config = config;
    model.range = range;
    [self.tempShortFrameMutableArray addObject:model];
}

- (CGFloat)maxLeadingHeight {
    CGFloat maxHeight = 0;
    for (CTShortFrameModel *model in self.tempShortFrameMutableArray) {
        CGFloat leadingHeight = model.attributedString.height - model.attributedString.lineHeight;
        if (leadingHeight > maxHeight)
            maxHeight = leadingHeight;
    }
    return maxHeight;
}

- (CGFloat)shortLineWidth {
    CGFloat width = 0;
    for (CTShortFrameModel *model in self.tempShortFrameMutableArray) {
        width += (model.attributedString.width + 2*model.config.borderHorizonSpacing);
    }
    return width;
}

- (CGFloat)maxLineHeightWithoutLeadingLanguage {
    CGFloat maxHeight = 0;
    for (CTShortFrameModel *model in self.tempShortFrameMutableArray) {
        CGFloat lineHeight = model.attributedString.lineHeight;
        if (model.attributedString.lineHeight > maxHeight)
            maxHeight = lineHeight;
    }
    return maxHeight;
}

- (CGFloat)maxLineVerticalHeight {
    CGFloat maxHeight = 0;
    for (CTShortFrameModel *model in self.tempShortFrameMutableArray) {
        CGFloat verticalHeight = model.config.borderVerticalSpacing;
        if (verticalHeight > maxHeight) {
            maxHeight = verticalHeight;
        }
    }
    return maxHeight;
}

- (CGFloat)maxLineHeight {
    CGFloat maxHeight = 0;
    for (CTShortFrameModel *model in self.tempShortFrameMutableArray) {
        CGFloat tempHeight = (model.attributedString.height + 2*model.config.borderVerticalSpacing);
        if (tempHeight > maxHeight)
            maxHeight = tempHeight;
    }
    return maxHeight;
}

- (CGRect)convertRect:(CGRect)rect {
    return CGRectMake(rect.origin.x, self.contextHeight - rect.origin.y - rect.size.height, rect.size.width, rect.size.height);
}

#pragma mark - 检测当拼接的状态

- (BOOL)greatThanBoundsHeight:(NSAttributedString *)attributedString config:(CTFrameParserConfig *)config{
    if ((self.yStart + attributedString.height + 2*config.borderVerticalSpacing) > self.contextHeight)
        return YES;
    return NO;
}

- (CTAttributedStringLengthType)attributedStringLengthType:(NSAttributedString *)attibutedString config:(CTFrameParserConfig *)config {
    if ((attibutedString.width + 2*config.borderHorizonSpacing) > self.contextWidth)
        return CTAttributedStringLengthTypeGreatOrEqualThanLine;
    return CTAttributedStringLengthTypeDefault;
}

- (CTAttributedStringNeedBorder)attributedStringNeedFrame:(CTFrameParserConfig *)config {
    if (config.needBorder) return CTAttributedStringNeedBorderYes;
    return CTAttributedStringNeedBorderDefault;
}

- (CTPieceLineCompleted)pieceLineCompleted:(NSAttributedString *)attributedString config:(CTFrameParserConfig *)config {
    if ((self.xStart + attributedString.width + 2*config.borderHorizonSpacing) > self.contextWidth)
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

- (NSMutableArray *)runRectModelArray {
    if (!_runRectModelArray) {
        _runRectModelArray = [NSMutableArray new];
    }
    return _runRectModelArray;
}

@end
