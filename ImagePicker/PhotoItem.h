
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface PhotoItem : NSObject

/**
 asset用于UploadImageView
 可以通过一个asset获得原图，通过这个方法：[[TZImageManager manager] getOriginalPhotoWithAsset:completion:]
 */
@property (nonatomic, strong) id asset;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic ,strong)UIImage  *thumbnailImage;
@property (nonatomic ,strong)UIImage  *originalImage;
@property (nonatomic ,strong)NSString *url;
@property (nonatomic ,strong)NSString *thumbnailUrl;
@property (nonatomic ,strong)NSString *imagePath;
@property (nonatomic ,strong)NSURL *imageURL;
@property (nonatomic ,strong)NSData *imageData;
@property (nonatomic, strong)NSString *ID;
@property (nonatomic ,strong, readonly) UIImage *capture;
@property (nonatomic ,strong, readonly) UIImage *placeholder;

@property (nonatomic ,strong)UIView   *sourceView;
@property (nonatomic ,assign)NSInteger index;

@property (nonatomic, assign)BOOL firstShow;

@property (nonatomic,strong) NSDictionary *originalData;

@end
