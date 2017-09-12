//
//  CLMosaicTool.m
//  WCEditImage
//
//  Created by william on 2017/9/11.
//  Copyright © 2017年 ybbc. All rights reserved.
//

#import "CLMosaicTool.h"
#import "GPUImage.h"

static NSString* const kCLSplashToolEraserIconName = @"eraserIconAssetsName";


@interface MosaicSlider : UISlider
@property (nonatomic, copy) void(^touchEnd)();
@end

@implementation MosaicSlider

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    if (_touchEnd) {
        _touchEnd();
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    if (_touchEnd) {
        _touchEnd();
    }
}

@end


@interface MosaicView : UIView

@property(nonatomic, assign) int drawType;  // 0: 涂抹 1: 擦除
@property(nonatomic, assign) int paintDegree;

@property(nonatomic, strong) NSMutableArray *lineArray;
@property(nonatomic, strong) NSMutableArray *pointArray;

@property(nonatomic, strong) UIImage *image;
@property(nonatomic, strong) UIImage *currentImage;
@property(nonatomic, strong) UIImage *originImage;
@property(nonatomic, strong) UIImage *filterImage;

- (instancetype)initWithImage:(UIImage *)image;

+ (instancetype)viewWithImage:(UIImage *)image;

- (UIImage *)savedImage;

@end

@implementation MosaicView

- (instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (instancetype)initWithImage:(UIImage *)image {
    self = [super init];
    if (self) {
        self.drawType = 0;
        self.paintDegree = 35;
        self.lineArray = [NSMutableArray array];
        
        self.image = image;
    }
    
    return self;
}

+ (instancetype)viewWithImage:(UIImage *)image {
    return [[self alloc] initWithImage:image];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.currentImage = [self scaleImage:self.image toSize:self.bounds.size];
    self.originImage = self.currentImage;
    self.filterImage = [self filterForGaussianBlur:self.originImage];
}

- (UIImage *)scaleImage:(UIImage *)image toSize:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

- (UIImage *)filterForGaussianBlur:(UIImage *)image {
    GPUImagePixellateFilter *filter = [[GPUImagePixellateFilter alloc] init];
    [filter forceProcessingAtSize:image.size];
    filter.fractionalWidthOfAPixel = 0.03f;
    
    GPUImagePicture *pic = [[GPUImagePicture alloc] initWithImage:image];
    [pic addTarget:filter];
    [pic processImage];
    [filter useNextFrameForImageCapture];
    return [filter imageFromCurrentFramebuffer];
}

- (void)setDrawType:(int)drawType {
    _drawType = drawType;
    
    self.currentImage = [self savedImage];
    self.lineArray = [NSMutableArray array];
    [self setNeedsDisplay];
}

- (void)setPaintDegree:(int)paintDegree {
    _paintDegree = paintDegree;
    
    self.currentImage = [self savedImage];
    self.lineArray = [NSMutableArray array];
    [self setNeedsDisplay];
}

- (void)initPoint2:(CGPoint)p {
    self.pointArray = [NSMutableArray array];
    [self.lineArray addObject:self.pointArray];
    [self addPoint2:p];
}

- (void)addPoint2:(CGPoint)p {
    NSValue *pointValue = [NSValue valueWithCGPoint:p];
    NSDictionary *pointDic = @{@"type" : @(self.drawType), @"point" : pointValue};
    [self.pointArray addObject:pointDic];
    
    [self setNeedsDisplay];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    CGPoint p = [[touches anyObject] locationInView:self];
    
    [self initPoint2:p];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    CGPoint p = [[touches anyObject] locationInView:self];
    
    [self addPoint2:p];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    CGPoint p = [[touches anyObject] locationInView:self];
    [self addPoint2:p];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    CGPoint p = [[touches anyObject] locationInView:self];
    [self addPoint2:p];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineCap(context, kCGLineCapRound); // 4. 设置线顶部的样式
    CGContextSetLineJoin(context, kCGLineJoinRound); // 5. 设置线连接处的样式 // 可以使线画出来更圆滑
    CGContextSetLineWidth(context, self.paintDegree); // 3. 设置线宽
    CGContextSetStrokeColorWithColor(context, [UIColor clearColor].CGColor);
    CGContextSetFillColorWithColor(context, [UIColor colorWithPatternImage:self.currentImage].CGColor);
    CGContextFillRect(context, rect);
    
    for (int i = 0; i < self.lineArray.count; i++) {
        NSMutableArray *array = [self.lineArray objectAtIndex:i];
        for (int i = 0; i < array.count; i++) {
            NSDictionary *dic = array[i];
            if ([dic[@"type"] intValue] == 0) {
                CGContextSetStrokeColorWithColor(context, [UIColor colorWithPatternImage:self.filterImage].CGColor);
            } else {
                CGContextSetStrokeColorWithColor(context, [UIColor colorWithPatternImage:self.originImage].CGColor);
            }
            CGContextSetLineWidth(context, self.paintDegree);
            
            NSValue *value = dic[@"point"];
            CGPoint p = [value CGPointValue];
            if (i == 0) {
                CGContextMoveToPoint(context, p.x, p.y);
                CGContextAddLineToPoint(context, p.x, p.y);
            } else {
                CGContextAddLineToPoint(context, p.x, p.y);
            }
        }
    }
    CGContextDrawPath(context, kCGPathFillStroke);
}

- (UIImage *)savedImage {
    CGRect rect = [self bounds];
    if (rect.size.width == 0 || rect.size.height == 0) {
        return nil;
    }
    UIGraphicsBeginImageContextWithOptions(rect.size, self.opaque, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self.layer renderInContext:context];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

@end



@implementation CLMosaicTool
{
    UIView *_menuView;
    MosaicSlider *_widthSlider;
    UIView *_strokePreview;
    UIView *_strokePreviewBackground;
    
    MosaicView *_mosaicView;
}

+ (NSArray*)subtools
{
    return nil;
}

+ (NSString*)defaultTitle
{
    return @"马赛克";
}

+ (BOOL)isAvailable
{
    return [[CLImageEditorTheme theme] containEditTypeForClass:[self class]];
}

+ (CGFloat)defaultDockedNumber
{
    return 1.2;
}

+ (NSString*)defaultIconImagePath
{
    NSString *path = [[CLImageEditorTheme theme].toolIconColor isEqualToString:@"white"] ? @"mosaic_white" : @"mosaic";
    return [NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] resourcePath],path];
}

#pragma mark- optional info

+ (NSDictionary*)optionalInfo
{
    return @{
             kCLSplashToolEraserIconName : @"",
             };
}

#pragma mark- implementation

- (void)setup
{
    _mosaicView = [MosaicView viewWithImage:self.editor.imageView.image];
    _mosaicView.frame = self.editor.imageView.bounds;
    [self.editor.imageView addSubview:_mosaicView];
    
    self.editor.imageView.userInteractionEnabled = YES;
    self.editor.scrollView.panGestureRecognizer.minimumNumberOfTouches = 2;
    self.editor.scrollView.panGestureRecognizer.delaysTouchesBegan = NO;
    self.editor.scrollView.pinchGestureRecognizer.delaysTouchesBegan = NO;
    
    _menuView = [[UIView alloc] initWithFrame:self.editor.menuView.frame];
    _menuView.backgroundColor = self.editor.menuView.backgroundColor;
    [self.editor.view addSubview:_menuView];
    
    [self setMenu];
    
    _menuView.transform = CGAffineTransformMakeTranslation(0, self.editor.view.height-_menuView.top);
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         _menuView.transform = CGAffineTransformIdentity;
                     }];
}

- (void)cleanup
{
    [_mosaicView removeFromSuperview];
    self.editor.imageView.userInteractionEnabled = NO;
    self.editor.scrollView.panGestureRecognizer.minimumNumberOfTouches = 1;
    
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         _menuView.transform = CGAffineTransformMakeTranslation(0, self.editor.view.height-_menuView.top);
                     }
                     completion:^(BOOL finished) {
                         [_menuView removeFromSuperview];
                     }];
}

- (void)executeWithCompletionBlock:(void (^)(UIImage *, NSError *, NSDictionary *))completionBlock
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *image = [_mosaicView savedImage];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(image, nil, nil);
        });
    });
}

#pragma mark-

- (MosaicSlider *)defaultSliderWithWidth:(CGFloat)width
{
    MosaicSlider *slider = [[MosaicSlider alloc] initWithFrame:CGRectMake(0, 0, width, 34)];
    
    [slider setMaximumTrackImage:[UIImage new] forState:UIControlStateNormal];
    [slider setMinimumTrackImage:[UIImage new] forState:UIControlStateNormal];
    [slider setThumbImage:[UIImage new] forState:UIControlStateNormal];
    slider.thumbTintColor = [UIColor whiteColor];
    CGFloat value = _mosaicView.paintDegree / 65.0;
    if (value < 0) {
        value = 0;
    } else if (value > 1) {
        value = 1;
    }
    slider.value = value;
    
    return slider;
}

- (UIImage*)widthSliderBackground
{
    CGSize size = _widthSlider.frame.size;
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    UIColor *color = [[[CLImageEditorTheme theme] toolbarTextColor] colorWithAlphaComponent:0.5];
    
    CGFloat strRadius = 1;
    CGFloat endRadius = size.height/2 * 0.6;
    
    CGPoint strPoint = CGPointMake(strRadius + 5, size.height/2 - 2);
    CGPoint endPoint = CGPointMake(size.width-endRadius - 1, strPoint.y);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddArc(path, NULL, strPoint.x, strPoint.y, strRadius, -M_PI/2, M_PI-M_PI/2, YES);
    CGPathAddLineToPoint(path, NULL, endPoint.x, endPoint.y + endRadius);
    CGPathAddArc(path, NULL, endPoint.x, endPoint.y, endRadius, M_PI/2, M_PI+M_PI/2, YES);
    CGPathAddLineToPoint(path, NULL, strPoint.x, strPoint.y - strRadius);
    
    CGPathCloseSubpath(path);
    
    CGContextAddPath(context, path);
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillPath(context);
    
    UIImage *tmp = UIGraphicsGetImageFromCurrentImageContext();
    
    CGPathRelease(path);
    
    UIGraphicsEndImageContext();
    
    return tmp;
}

- (void)setMenu
{
    CGFloat W = 70;
    
    _widthSlider = [self defaultSliderWithWidth:_menuView.width - W - 20];
    _widthSlider.left = 10;
    _widthSlider.top = _menuView.height/2 - _widthSlider.height/2;
    [_widthSlider addTarget:self action:@selector(widthSliderDidChange:) forControlEvents:UIControlEventValueChanged];
    __weak typeof(self) weak = self;
    _widthSlider.touchEnd = ^{
        [weak sliderTouchEnd];
    };
    _widthSlider.backgroundColor = [UIColor colorWithPatternImage:[self widthSliderBackground]];
    [_menuView addSubview:_widthSlider];
    
    _strokePreview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, W - 5, W - 5)];
    _strokePreview.layer.cornerRadius = _strokePreview.height/2;
    _strokePreview.layer.borderWidth = 1;
    _strokePreview.layer.borderColor = [[[CLImageEditorTheme theme] toolbarTextColor] CGColor];
    _strokePreview.center = CGPointMake(_menuView.width-W/2, _menuView.height/2);
    [_menuView addSubview:_strokePreview];
    
    _strokePreviewBackground = [[UIView alloc] initWithFrame:_strokePreview.frame];
    _strokePreviewBackground.layer.cornerRadius = _strokePreviewBackground.height/2;
    _strokePreviewBackground.alpha = 0.3;
    [_menuView insertSubview:_strokePreviewBackground aboveSubview:_strokePreview];
    
    _strokePreview.backgroundColor = [[CLImageEditorTheme theme] toolbarTextColor];
    _strokePreviewBackground.backgroundColor = _strokePreview.backgroundColor;
    
    [self widthSliderDidChange:_widthSlider];
    
    _menuView.clipsToBounds = NO;
}

- (void)widthSliderDidChange:(UISlider*)sender
{
    CGFloat scale = MAX(0.05, _widthSlider.value);
    _strokePreview.transform = CGAffineTransformMakeScale(scale, scale);
    _strokePreview.layer.borderWidth = 2/scale;
}

- (void)sliderTouchEnd {
    _mosaicView.paintDegree = MAX(1, _widthSlider.value * 65);
}

@end
