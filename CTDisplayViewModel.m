//
//  CTDisplayViewModel.m
//  CTTest
//
//  Created by chiery on 2016/8/15.
//  Copyright © 2016年 My-Zone. All rights reserved.
//

#import "CTDisplayViewModel.h"
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

@interface CTDisplayViewModel ()
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

@implementation CTDisplayViewModel

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
    if (range.length == 0) return;
    NSAttributedString *attributedString = [self.attributedString attributedSubstringFromRange:range];
    if ([self greatThanBoundsHeight:attributedString]) {self.yStart = CGFLOAT_MAX; return;}
    
    switch ([self attributedStringJoin]) {
        case CTAttributedStringJoinDefault:
            switch ([self attributedStringLengthType:attributedString]) {
                case CTAttributedStringLengthTypeDefault:
                    [self addShortFrameModel:attributedString config:config range:range];
                    [self.frameMutableArray addObject:config];
                    [self setXStart:self.xStart + attributedString.width];
                    break;
                case CTAttributedStringLengthTypeGreatOrEqualThanLine:
                    [self addCompletedLineRef:range config:config];
                    break;
            }
            break;
        case CTAttributedStringJoinMiddle:
            switch ([self pieceLineCompleted:attributedString]) {
                case CTPieceLineCompletedDefault:
                    [self addShortFrameModel:attributedString config:config range:range];
                    [self.frameMutableArray addObject:config];
                    [self setXStart:self.xStart + attributedString.width];
                    break;
                case CTPieceLineCompletedDone:
                    switch ([self attributedStringNeedFrame:config]) {
                        case CTAttributedStringNeedBorderDefault:
                            [self addBreakAttributesStringWithRange:range config:config];
                            break;
                        case CTAttributedStringNeedBorderYes:
                            [self addPieceLineRef];
                            [self setXStart:0];
                            [self createLineRefWithRange:range config:config];
                            break;
                    }
                    break;
            }
            break;
    }
}

#pragma mark - 整理行环境
- (void)addCompletedLineRef:(NSRange)range config:(CTFrameParserConfig *)config {
    NSAttributedString *attributedString = [self.attributedString attributedSubstringFromRange:range];
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGRect tempRect = CGRectInset([self convertRect:CGRectMake(self.xStart, self.yStart, CGRectGetWidth(self.contextBounds), attributedString.height + 2 * config.borderVerticalSpacing)], config.borderHorizonSpacing, config.borderVerticalSpacing);
    CGPathAddRect(path, NULL, tempRect);
    CTFrameRef frame = CTFramesetterCreateFrame(self.framesetter, CFRangeMake(range.location, range.length), path, NULL);
    [self.frameRefMutableArray addObject:(__bridge id _Nonnull)(frame)];
    [self.frameMutableArray addObject:config];
    CFRelease(frame);
    CFRelease(path);
    self.yStart += (attributedString.height + 2 * config.borderVerticalSpacing);

    
    CFRange frameRange = CTFrameGetVisibleStringRange(frame);
    [self createLineRefWithRange:NSMakeRange(frameRange.length + range.location, range.length - frameRange.length) config:config];
}

- (void)addPieceLineRef {
    if (self.tempShortFrameMutableArray.count == 0) return;
    [self setXStart:0];
    [self createShortLineFrameRef:[self maxLineHeight]];
    [self setYStart:self.yStart + [self maxLineHeight]];
    [self.tempShortFrameMutableArray removeAllObjects];
}

- (void)createShortLineFrameRef:(CGFloat)maxLineHeight {
    
    for (CTShortFrameModel *model in self.tempShortFrameMutableArray) {
        CGMutablePathRef path = CGPathCreateMutable();
        CGRect tempRect = CGRectInset([self convertRect:CGRectMake(self.xStart, self.yStart + maxLineHeight - (model.attributedString.height + 2*model.config.borderVerticalSpacing), model.attributedString.width + 2*model.config.borderHorizonSpacing, model.attributedString.height + 2 * model.config.borderVerticalSpacing)], model.config.borderHorizonSpacing, model.config.borderVerticalSpacing);
        CGPathAddRect(path, NULL, tempRect);
        CTFrameRef frame = CTFramesetterCreateFrame(self.framesetter, CFRangeMake(model.range.location, model.range.length), path, NULL);
        [self.frameRefMutableArray addObject:(__bridge id _Nonnull)(frame)];
        CFRelease(frame);
        CFRelease(path);
        
        self.xStart += (model.attributedString.width + 2*model.config.borderHorizonSpacing);
    }
}

- (void)addBreakAttributesStringWithRange:(NSRange)range config:(CTFrameParserConfig *)config {
    self.xStart = 0;
    NSAttributedString *attributedString = [self.attributedString attributedSubstringFromRange:range];

    CGFloat maxLineHeight = [self maxLineHeight]>(attributedString.height + 2*config.borderVerticalSpacing)?[self maxLineHeight]:(attributedString.height + 2*config.borderVerticalSpacing);
    [self createShortLineFrameRef:maxLineHeight];
    [self.tempShortFrameMutableArray removeAllObjects];
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGRect tempRect = CGRectInset([self convertRect:CGRectMake(self.xStart, self.yStart + maxLineHeight - (attributedString.height + 2*config.borderVerticalSpacing), CGRectGetWidth(self.contextBounds) - self.xStart, (attributedString.height + 2*config.borderVerticalSpacing))], config.borderHorizonSpacing, config.borderVerticalSpacing);
    CGPathAddRect(path, NULL, tempRect);
    CTFrameRef frame = CTFramesetterCreateFrame(self.framesetter, CFRangeMake(range.location, range.length), path, NULL);
    [self.frameRefMutableArray addObject:(__bridge id _Nonnull)(frame)];
    [self.frameMutableArray addObject:config];
    CFRelease(path);
    
    self.yStart += maxLineHeight;
    self.xStart = 0;
    
    CFRange frameRange = CTFrameGetVisibleStringRange(frame);
    CFRelease(frame);
    [self createLineRefWithRange:NSMakeRange(frameRange.length + range.location, range.length - frameRange.length) config:config];

    
}

- (void)addShortFrameModel:(NSAttributedString *)attributedString config:(CTFrameParserConfig *)config range:(NSRange)range {
    CTShortFrameModel *model = [CTShortFrameModel new];
    model.attributedString = attributedString;
    model.config = config;
    model.range = range;
    [self.tempShortFrameMutableArray addObject:model];
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

- (BOOL)greatThanBoundsHeight:(NSAttributedString *)attributedString {
    if (self.yStart + attributedString.height > CGRectGetHeight(self.contextBounds))
        return YES;
    return NO;
}

- (CTAttributedStringLengthType)attributedStringLengthType:(NSAttributedString *)attibutedString {
    if (attibutedString.width > CGRectGetWidth(self.contextBounds))
        return CTAttributedStringLengthTypeGreatOrEqualThanLine;
    return CTAttributedStringLengthTypeDefault;
}

- (CTAttributedStringNeedBorder)attributedStringNeedFrame:(CTFrameParserConfig *)config {
    if (config.needBorder) return CTAttributedStringNeedBorderYes;
    return CTAttributedStringNeedBorderDefault;
}

- (CTPieceLineCompleted)pieceLineCompleted:(NSAttributedString *)attributedString {
    if (self.xStart + attributedString.width > CGRectGetWidth(self.contextBounds))
        return CTPieceLineCompletedDone;
    return CTPieceLineCompletedDefault;
}

- (CTAttributedStringJoin)attributedStringJoin {
    if (self.xStart == 0)
        return CTAttributedStringJoinDefault;
    return CTAttributedStringJoinMiddle;
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
