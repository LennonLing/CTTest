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

- (CGFloat)height {
//    CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef)self);
//    
//    CGFloat ascent;
//    CGFloat descent;
//    CGFloat leading;
//    // get bounds info
//    CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
//    return ceil(ascent + descent + leading);
    
    CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef)self);
    return CTLineGetBoundsWithOptions(line,kCTLineBoundsIncludeLanguageExtents).size.height;
}

- (CGFloat)width {
    CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef)self);
    return CTLineGetBoundsWithOptions(line,kCTLineBoundsExcludeTypographicLeading).size.width;
}


@end
