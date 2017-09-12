//
//  ImagePickerBrowser.h
//  TZImagePickerController
//
//  Created by william on 2016/12/23.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PhotoItem.h"

typedef enum {
    PickerBrowserBothAlert = 0,//UIActionSheet
    PickerBrowserBothNormal,//相册内部相机按钮
    PickerBrowserAlbum,//相册
    PickerBrowserCamera,//相机
} PickerBrowserType;

typedef void(^FinishPickingPhotos)(NSArray<PhotoItem *> *images, BOOL isSelectOriginalPhoto);

@interface ImagePickerBrowser : NSObject

/**
 图片选择器

 @param controller 弹出controller
 @param type 弹出类型
 @param allowEdit 是否允许编辑图片，只有当maxCount为1或者相机选择才有效
 @param maxCount 最大选择图片数
 @param selectedImages 已经选择的图片
 @param isSelectOriginalPhoto 当前选择是否原图
 @param finishPickingPhotos 选择完成block
 */
- (instancetype)initWithController:(UIViewController *)controller type:(PickerBrowserType)type allowEdit:(BOOL)allowEdit maxCount:(NSInteger)maxCount selectedImages:(NSArray<PhotoItem *> *)selectedImages isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto complete:(FinishPickingPhotos)finishPickingPhotos;
@end
