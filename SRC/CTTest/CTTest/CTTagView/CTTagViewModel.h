//
//  CTDisplayViewModel.h
//  CTTest
//
//  Created by chiery on 2016/8/15.
//  Copyright © 2016年 My-Zone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CTTagViewModel : NSObject

/**
 *  组装成可供绘制的数组，供drawRect使用
 */
@property (nonatomic, strong, readonly) NSArray *frameRefArray;

/**
 *  数组中的值与frameRefArray中的值一一对应，对应着frameRef需不需要加上一个边框
 */
@property (nonatomic, strong, readonly) NSArray *frameArray;


/**
 *  提供需要绘制的文字以及边界
 *
 *  @param attributedString 富文本
 *  @param bounds           绘制文字区域
 *
 *  @return model
 */
- (instancetype)initWithAttributedString:(NSAttributedString *)attributedString andBounds:(CGRect)bounds;

@end
