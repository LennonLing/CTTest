//
//  CTDisplayView.h
//  CTTest
//
//  Created by chiery on 2016/8/1.
//  Copyright © 2016年 My-Zone. All rights reserved.
//

#import <UIKit/UIKit.h>

extern const NSString * _Nullable CTAttributedStringNeedBorder;
extern const NSString * _Nullable CTAttributedStringBorderWidth;
extern const NSString * _Nullable CTAttributedStringBorderColor;
extern const NSString * _Nullable CTAttributedStringBorderCornerRadius;
extern const NSString * _Nullable CTAttributedStringBorderHorizonSpacing;
extern const NSString * _Nullable CTAttributedStringBorderVerticalSpacing;



@interface CTTagView : UIView

/**
 *  在这个特殊的定制的界面中只是添加这么一个特殊的属性，作为信息的唯一来源
 */
@property(nullable, nonatomic,copy)   NSAttributedString *attributedText NS_AVAILABLE_IOS(6_0);  // default is nil

@end
