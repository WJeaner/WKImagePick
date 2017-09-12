//
//  UploadImageView.h
//  TZImagePickerController
//
//  Created by william on 2016/12/26.
//

#import <UIKit/UIKit.h>
#import "ImagePickerBrowser.h"

@interface UploadImageView : UICollectionView
/**
 可以通过一个asset获得原图，通过这个方法：[[TZImageManager manager] getOriginalPhotoWithAsset:completion:]
 */
@property (nonatomic, assign) BOOL allowPickingOriginal;//允许选择原图
@property (nonatomic, assign) BOOL isSelectOriginalPhoto;//是否选中原图
@property (nonatomic, assign) BOOL canEdit;//是否可以添加编辑
@property (nonatomic, strong) NSMutableArray *selectImageItems;//选择的ImagePickerItem
@property (nonatomic, copy) void(^beginAdd)();//点击添加或者预览图片
@property (nonatomic, copy) void(^addFinish)(NSArray *imagesArray);//如果执行则不刷新
@property (nonatomic, copy) void(^didChangeFrame)(UploadImageView *view);//刷新的时候改变frame
- (instancetype)initWithFrame:(CGRect)frame controller:(UIViewController *)controller type:(PickerBrowserType)type allowEdit:(BOOL)allowEdit maxCount:(NSInteger)maxCount lineCount:(NSInteger)lineCount space:(CGFloat)space canEdit:(BOOL)canEdit defImage:(NSString *)def;
- (void)reloadWithImages:(NSArray *)array;
@end
