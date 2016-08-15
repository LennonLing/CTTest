//
//  CTDisplayView.m
//  CTTest
//
//  Created by chiery on 2016/8/1.
//  Copyright © 2016年 My-Zone. All rights reserved.
//

#import "CTDisplayView.h"
#import <CoreText/CoreText.h>

@interface CTDisplayViewModel : NSObject

// attribute info
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIColor *boderColor;
@property (nonatomic) CGFloat boderWidth;
@property (nonatomic) CGFloat borderCornerRadius;

// builder
- (void)builder;

// readobly
@property (nonatomic, readonly) CGFloat lineAscent;
@property (nonatomic, readonly) CGFloat lineDescent;
@property (nonatomic, readonly) CGFloat lineLeading;
@property (nonatomic, readonly) CGRect lineBounds;
@property (nonatomic, strong, readonly) NSMutableAttributedString *attributedString;

@end

@interface CTDisplayViewModel ()
@property (nonatomic, readwrite) CGFloat lineAscent;
@property (nonatomic, readwrite) CGFloat lineDescent;
@property (nonatomic, readwrite) CGFloat lineLeading;
@property (nonatomic, readwrite) CGRect lineBounds;
@property (nonatomic, strong, readwrite) NSMutableAttributedString *attributedString;
@end

@implementation CTDisplayViewModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initProperty];
    }
    return self;
}

- (void)initProperty {
    _text = @"您还没有给定要设置的文字";
    _font = [UIFont systemFontOfSize:15];
    _textColor = [UIColor blackColor];
    _boderWidth = 1.0f;
    _borderCornerRadius = 3.0f;
    _boderColor = [UIColor redColor];
}

- (void)builder {
    // alloc attributedString
    [self buildAttributtedString];
    // get bounds info
    [self getCTLineRefBoundsInfo];
}

- (void)buildAttributtedString {
    self.attributedString = [[NSMutableAttributedString alloc] initWithString:self.text
                                                                   attributes:@{
                                                                                NSFontAttributeName:self.font,
                                                                                NSForegroundColorAttributeName:self.textColor
                                                                                }];
}

- (void)getCTLineRefBoundsInfo {
    CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef)self.attributedString);
    
    // get bounds info
    CTLineGetTypographicBounds(line, &_lineAscent, &_lineDescent, &_lineLeading);
    _lineBounds = CTLineGetBoundsWithOptions(line,kCTLineBoundsExcludeTypographicLeading);
}

@end

@implementation CTDisplayView

// delegate
void RunDelegateDeallocCallback( void* refCon ){}

CGFloat RunDelegateGetAscentCallback( void *refCon ){
    CTDisplayViewModel *model = (__bridge CTDisplayViewModel *)refCon;
    return model.lineAscent;
}

CGFloat RunDelegateGetDescentCallback(void *refCon){
    CTDisplayViewModel *model = (__bridge CTDisplayViewModel *)refCon;
    return model.lineDescent;
}

CGFloat RunDelegateGetWidthCallback(void *refCon){
    CTDisplayViewModel *model = (__bridge CTDisplayViewModel *)refCon;
    return CGRectGetWidth(model.lineBounds);
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    // 步骤 1  生成当前的环境
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // 步骤 2  转换坐标系
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    // 步骤 3  生成绘制文字的path
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, self.bounds);
    
    // 步骤 4  组织attributeString,开始渲染
    NSMutableAttributedString *attString = [[NSMutableAttributedString alloc] initWithString:@"Hello World! "
                                     "  ，CoreText 本身支持        各种文字排版的区域，"
                                     " 我们这里简单地将 UIView 的整个界面作为排版的区域。"
                                     " 为了加深理解，建议读者将该步骤的代码替换成如下代码，"
                                     " 测试设置不同的绘制区域带来的界面变化。"];
    
    
    //为文字设置CTRunDelegate,delegate决定留给文字的空间大小
    CTDisplayViewModel *model = [CTDisplayViewModel new];
    model.font = [UIFont systemFontOfSize:30];
    model.textColor = [UIColor redColor];
    model.boderWidth = 1.0f;
    model.boderColor = [UIColor blueColor];
    model.borderCornerRadius = 2.0f;
    model.text = @"创建绘制的区域";
    [model builder];
    
    CTRunDelegateCallbacks textCallbacks;
    textCallbacks.version = kCTRunDelegateVersion1;
    textCallbacks.dealloc = RunDelegateDeallocCallback;
    textCallbacks.getAscent = RunDelegateGetAscentCallback;
    textCallbacks.getDescent = RunDelegateGetDescentCallback;
    textCallbacks.getWidth = RunDelegateGetWidthCallback;
    CTRunDelegateRef runDelegate = CTRunDelegateCreate(&textCallbacks, (__bridge void * _Nullable)(model));
    // 增加处理文本渲染时的代理
    [attString addAttribute:(NSString *)kCTRunDelegateAttributeName value:(__bridge id _Nonnull)(runDelegate) range:NSMakeRange(14, 1)];
    [attString addAttribute:@"addRectTag" value:model range:NSMakeRange(14, 1)];
    
    
    // 设置段落样式
    CTParagraphStyleSetting lineBreakMode;
    CTLineBreakMode lineBreak = kCTLineBreakByWordWrapping;//kCTLineBreakByCharWrapping;//换行模式
    lineBreakMode.spec = kCTParagraphStyleSpecifierLineBreakMode;
    lineBreakMode.value = &lineBreak;
    lineBreakMode.valueSize = sizeof(CTLineBreakMode);
    
    //组合设置
    CTParagraphStyleSetting settings[] = {
        lineBreakMode,
    };
    
    //通过设置项产生段落样式对象
    CTParagraphStyleRef style = CTParagraphStyleCreate(settings, 1);
    
    
    [attString addAttributes:@{
                               NSFontAttributeName:[UIFont systemFontOfSize:30],
                               NSForegroundColorAttributeName:[UIColor redColor],
                               @"addRect":@(YES)
                               } range:[attString.string rangeOfString:@"本身支持"]];
    
    
    [attString addAttributes:@{
                               NSFontAttributeName:[UIFont systemFontOfSize:17],
                               NSForegroundColorAttributeName:[UIColor yellowColor],
                               @"addRect":@(YES),
                               (id)kCTParagraphStyleAttributeName:(id)style,
                               } range:[attString.string rangeOfString:@"我们这里简单地将"]];
    
    
    
    CTFramesetterRef framesetter =
    CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attString);
    CTFrameRef frame =
    CTFramesetterCreateFrame(framesetter,
                             CFRangeMake(0, 0), path, NULL);
    
    
    CFArrayRef lines = CTFrameGetLines(frame);
    CGPoint lineOrigins[CFArrayGetCount(lines)];
    CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), lineOrigins);

    for (int i = 0; i < CFArrayGetCount(lines); i++) {
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        CGFloat lineAscent;
        CGFloat lineDescent;
        CGFloat lineLeading;
        CTLineGetTypographicBounds(line, &lineAscent, &lineDescent, &lineLeading);
        
        CFArrayRef runs = CTLineGetGlyphRuns(line);

        for (int j = 0; j < CFArrayGetCount(runs); j++) {
            CGFloat runAscent;
            CGFloat runDescent;
            CGPoint lineOrigin = lineOrigins[i];
            CTRunRef run = CFArrayGetValueAtIndex(runs, j);
            NSDictionary* attributes = (NSDictionary*)CTRunGetAttributes(run);
            
            /* 方案二：
             
             预留需要绘制文本的size, 在这个size上重新绘制文本，边框的size可以自定义。
            
            CTDisplayViewModel *model = [attributes objectForKey:@"addRectTag"];
            
            if (model) {
                NSString *modelString = model.text;
                if (modelString) {
                    CGRect runRect;
                    runRect.size.width = CTRunGetTypographicBounds(run, CFRangeMake(0,0), &runAscent, &runDescent, NULL);
                    runRect=CGRectMake(lineOrigin.x + CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, NULL), lineOrigin.y - runDescent, runRect.size.width, runAscent + runDescent);
                    
                    CGMutablePathRef path = CGPathCreateMutable();
                    
                    // 初始化矩形位置，放置文字
                    CGPathAddRect(path, NULL, runRect);
                    
                    // 绘制边框，微边框绘制颜色
                    [[UIColor redColor] set];
                    if (runRect.size.width > 4.0f) {
                        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:runRect cornerRadius:1.0f];
                        path.lineWidth = 0.5f;
                        [path stroke];
                    }
                    
                    CTFramesetterRef framesetter =
                    CTFramesetterCreateWithAttributedString((CFMutableAttributedStringRef)model.attributedString);
                    CTFrameRef frame = CTFramesetterCreateFrame(framesetter,
                                                                CFRangeMake(0, 0), path, NULL);
                    CTFrameDraw(frame, context);
                    CFRelease(frame);
                    CFRelease(path);
                    CFRelease(framesetter);
                }
            }
             */
            
/*            方案一：
              在绘制完成的文本上，找到需要加边框的CTLine。加上边框
            
//            BOOL needAddRect = [[attributes objectForKey:@"addRect"] boolValue];
//            //图片渲染逻辑
//            if (needAddRect) {
//                
//                NSLog(@"========********=======");
//                NSLog(@"%@",attributes);
//                
//                CGRect runRect;
//                runRect.size.width = CTRunGetTypographicBounds(run, CFRangeMake(0,0), &runAscent, &runDescent, NULL);
//                runRect=CGRectMake(lineOrigin.x + CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, NULL), lineOrigin.y - runDescent, runRect.size.width, runAscent + runDescent);
//                
//                NSLog(@"*************************self.bounds****************************");
//                NSLog(@"%@",NSStringFromCGRect(self.bounds));
//                
//                NSLog(@"-------------------------runRect------------------------------");
//                NSLog(@"%@",NSStringFromCGRect(runRect));
//                
//                
//                
//
//                
//                /*
//                 *  这是在文字渲染好了的情况下定义的一种方式，这种方式只是在CTRun加上了一个边框，置于想变动里面文字的排版。
//                 *  就变得不可能了，这种方式的边框还是有一定的局限性
//                // 获取需要边框的文字的range
//                
//                [[UIColor redColor] set];
//                if (runRect.size.width > 4.0f) {
//                    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:runRect cornerRadius:1.0f];
//                    path.lineWidth = 0.5f;
//                    [path stroke];
//                }
//                 
//                 */
//                
//                UIImage *image  = [UIImage imageNamed:@"apple"];
//                
//                CGContextDrawImage(context,CGRectMake(0, 0, 100, 100), image.CGImage);
//                
//            }*/
        }
    }
    
    
    // 步骤 5  绘制
    CTFrameDraw(frame, context);

    
    
    // 步骤 6  释放已经存在的对象
    CFRelease(frame);
    CFRelease(path);
    CFRelease(framesetter);
    
}



@end
