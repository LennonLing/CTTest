//
//  NSMutableAttributedString+Line.m
//  CTTest
//
//  Created by chiery on 2016/8/15.
//  Copyright © 2016年 My-Zone. All rights reserved.
//

#import "NSAttributedString+Line.h"
#import <CoreText/CoreText.h>

@implementation NSAttributedString (Line)

- (CGFloat)lineHeight {
    CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef)self);
    CGFloat ascent;
    CGFloat descent;
    CGFloat leading;
    // get bounds info
    CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
    CFRelease(line);
    return ceil(ascent + descent);
}

- (CGFloat)height {
    CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef)self);
    CGFloat height = CTLineGetBoundsWithOptions(line,kCTLineBoundsIncludeLanguageExtents).size.height;
    CFRelease(line);
    return height;
}

- (CGFloat)width {
    CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef)self);
    CGFloat width = CTLineGetBoundsWithOptions(line,kCTLineBoundsExcludeTypographicLeading).size.width;
    CFRelease(line);
    return width;
}


@end
