//
//  CTFrameParser.h
//  CTTest
//
//  Created by chiery on 2016/8/17.
//  Copyright © 2016年 My-Zone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTFrameParserConfig.h"

@interface CTFrameParser : NSObject

+ (NSDictionary *)attributesWithConfig:(CTFrameParserConfig *)config;
+ (CTFrameParserConfig *)configWithAttributes:(NSDictionary *)dictionary;

@end
