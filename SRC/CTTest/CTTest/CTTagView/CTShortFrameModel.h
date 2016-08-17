//
//  CTShortFrameModel.h
//  CTTest
//
//  Created by chiery on 2016/8/17.
//  Copyright © 2016年 My-Zone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTFrameParserConfig.h"

@interface CTShortFrameModel : NSObject

@property (nonatomic, strong) NSAttributedString *attributedString;
@property (nonatomic, strong) CTFrameParserConfig *config;
@property (nonatomic, assign) NSRange range;

@end
