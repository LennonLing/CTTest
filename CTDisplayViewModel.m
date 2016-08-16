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
@property (nonatomic, strong) NSMutableArray *tempShortAttributedStringArray;
@property (nonatomic, strong) NSMutableArray *tempShortAttributedStringRangeArray;

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
                                               if (strongSelf) [strongSelf createLineRefWithRange:range attributedInfo:attrs];
                                           }];
}

- (void)addEndAttributedString{
    [self addPieceLineRef];
}

- (void)createLineRefWithRange:(NSRange)range attributedInfo:(NSDictionary *)attrs{
    if (range.length == 0) return;
    NSAttributedString *attributedString = [self.attributedString attributedSubstringFromRange:range];
    if ([self greatThanBoundsHeight:attributedString]) {self.yStart = CGFLOAT_MAX; return;}
    
    switch ([self attributedStringJoin]) {
        case CTAttributedStringJoinDefault:
            switch ([self attributedStringLengthType:attributedString]) {
                case CTAttributedStringLengthTypeDefault:
                    [self.tempShortAttributedStringArray addObject:attributedString];
                    [self.tempShortAttributedStringRangeArray addObject:[self dictionaryFromeRange:range]];
                    [self.frameMutableArray addObject:@([self attributedStringNeedFrame:attrs])];
                    [self setXStart:self.xStart + attributedString.width];
                    break;
                case CTAttributedStringLengthTypeGreatOrEqualThanLine:
                    [self addCompletedLineRef:range attributedInfo:attrs];
                    break;
            }
            break;
        case CTAttributedStringJoinMiddle:
            switch ([self pieceLineCompleted:attributedString]) {
                case CTPieceLineCompletedDefault:
                    [self.tempShortAttributedStringArray addObject:attributedString];
                    [self.tempShortAttributedStringRangeArray addObject:[self dictionaryFromeRange:range]];
                    [self.frameMutableArray addObject:@([self attributedStringNeedFrame:attrs])];
                    [self setXStart:self.xStart + attributedString.width];
                    break;
                case CTPieceLineCompletedDone:
                    switch ([self attributedStringNeedFrame:attrs]) {
                        case CTAttributedStringNeedBorderDefault:
                            [self addBreakAttributesStringWithRange:range attributedInfo:attrs];
                            break;
                        case CTAttributedStringNeedBorderYes:
                            [self addPieceLineRef];
                            [self setXStart:0];
                            [self createLineRefWithRange:range attributedInfo:attrs];
                            break;
                    }
                    break;
            }
            break;
    }
}

#pragma mark - 整理行环境
- (void)addCompletedLineRef:(NSRange)range attributedInfo:(NSDictionary *)attrs {
    NSAttributedString *attributedString = [self.attributedString attributedSubstringFromRange:range];
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, CGRectInset([self convertRect:CGRectMake(self.xStart, self.yStart, CGRectGetWidth(self.contextBounds), attributedString.height)], 2, 3));
    CTFrameRef frame = CTFramesetterCreateFrame(self.framesetter, CFRangeMake(range.location, range.length), path, NULL);
    [self.frameRefMutableArray addObject:(__bridge id _Nonnull)(frame)];
    [self.frameMutableArray addObject:@([self attributedStringNeedFrame:attrs])];
    CFRelease(frame);
    CFRelease(path);
    self.yStart += attributedString.height;

    
    CFRange frameRange = CTFrameGetVisibleStringRange(frame);
    [self createLineRefWithRange:NSMakeRange(frameRange.length + range.location, range.length - frameRange.length) attributedInfo:attrs];
}

- (void)addPieceLineRef {
    if (self.tempShortAttributedStringArray.count == 0) return;
    self.xStart = 0;
    [self createShortLineFrameRef:[self maxLineHeight]];
    self.yStart += [self maxLineHeight];
    [self.tempShortAttributedStringArray removeAllObjects];
    [self.tempShortAttributedStringRangeArray removeAllObjects];
}

- (void)createShortLineFrameRef:(CGFloat)maxLineHeight {
    for (NSInteger i = 0; i < self.tempShortAttributedStringArray.count; i++) {
        NSAttributedString *attributedString = self.tempShortAttributedStringArray[i];
        NSRange range = [self rangeFromDictionary:self.tempShortAttributedStringRangeArray[i]];
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, CGRectInset([self convertRect:CGRectMake(self.xStart, self.yStart + maxLineHeight - attributedString.height, attributedString.width, attributedString.height)], 2, 3));
        CTFrameRef frame = CTFramesetterCreateFrame(self.framesetter, CFRangeMake(range.location, range.length), path, NULL);
        [self.frameRefMutableArray addObject:(__bridge id _Nonnull)(frame)];
        CFRelease(frame);
        CFRelease(path);
        self.xStart += attributedString.width;
    }
}

- (void)addBreakAttributesStringWithRange:(NSRange)range attributedInfo:(NSDictionary *)attrs {
    self.xStart = 0;
    NSAttributedString *attributedString = [self.attributedString attributedSubstringFromRange:range];

    CGFloat maxLineHeight = [self maxLineHeight]>attributedString.height?[self maxLineHeight]:attributedString.height;
    [self createShortLineFrameRef:maxLineHeight];
    [self.tempShortAttributedStringArray removeAllObjects];
    [self.tempShortAttributedStringRangeArray removeAllObjects];
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, CGRectInset([self convertRect:CGRectMake(self.xStart, self.yStart + maxLineHeight - attributedString.height, CGRectGetWidth(self.contextBounds) - self.xStart, attributedString.height)], 2, 3));
    CTFrameRef frame = CTFramesetterCreateFrame(self.framesetter, CFRangeMake(range.location, range.length), path, NULL);
    [self.frameRefMutableArray addObject:(__bridge id _Nonnull)(frame)];
    [self.frameMutableArray addObject:@(NO)];
    CFRelease(path);
    
    self.yStart += maxLineHeight;
    self.xStart = 0;
    
    CFRange frameRange = CTFrameGetVisibleStringRange(frame);
    CFRelease(frame);
    [self createLineRefWithRange:NSMakeRange(frameRange.length + range.location, range.length - frameRange.length) attributedInfo:attrs];

    
}

- (NSDictionary *)dictionaryFromeRange:(NSRange)range {
    return @{
             @"location":@(range.location),
             @"length":@(range.length)
             };
}

- (NSRange)rangeFromDictionary:(NSDictionary *)dict {
    return NSMakeRange([dict[@"location"] integerValue], [dict[@"length"] integerValue]);
}

- (CGFloat)maxLineHeight {
    CGFloat maxHeight = 0;
    for (NSAttributedString *attributedString in self.tempShortAttributedStringArray) {
        if (attributedString.height > maxHeight)
            maxHeight = attributedString.height;
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

- (BOOL)end:(NSAttributedString *)attributedString {
    NSRange range = [@"高。" rangeOfString:self.attributedString.string];
    if (range.length + range.location == self.attributedString.length) {
        return YES;
    }
    return NO;
}

- (CTAttributedStringLengthType)attributedStringLengthType:(NSAttributedString *)attibutedString {
    if (attibutedString.width > CGRectGetWidth(self.contextBounds))
        return CTAttributedStringLengthTypeGreatOrEqualThanLine;
    return CTAttributedStringLengthTypeDefault;
}

- (CTAttributedStringNeedBorder)attributedStringNeedFrame:(NSDictionary *)attris {
    if ([[attris valueForKey:@"CTAttributedStringNeedBorder"] boolValue])
        return CTAttributedStringNeedBorderYes;
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

- (NSMutableArray *)tempShortAttributedStringArray {
    if (!_tempShortAttributedStringArray) {
        _tempShortAttributedStringArray = [NSMutableArray new];
    }
    return _tempShortAttributedStringArray;
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

- (NSMutableArray *)tempShortAttributedStringRangeArray {
    if (!_tempShortAttributedStringRangeArray) {
        _tempShortAttributedStringRangeArray = [NSMutableArray new];
    }
    return _tempShortAttributedStringRangeArray;
}

@end
