#import "PhotoItem.h"

@implementation PhotoItem

- (UIImage *)capture:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, YES, 0.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

- (void)setSourceView:(UIView *)sourceView
{
    _sourceView = sourceView;
    if (sourceView.clipsToBounds) {
        _capture = [self capture:sourceView];
    }
}
@end
