//
//  UploadImageView.m
//  TZImagePickerController
//
//  Created by william on 2016/12/26.
//

#import "UploadImageView.h"
#import "TZImagePickerController.h"
#import "ImagePickerBrowser.h"
#import "TZTestCell.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>
#import "LxGridViewFlowLayout.h"
#import "TZImageManager.h"
#import "TZVideoPlayerController.h"
#import "TZPhotoPreviewController.h"
#import "TZGifPhotoPreviewController.h"

@interface UploadImageView ()<UICollectionViewDelegate,UICollectionViewDataSource>
{
    BOOL _allowPickingGif;
    
    CGFloat _itemWH;
    ImagePickerBrowser *_imagePickerBrowser;
    
    NSInteger _maxCount;
    NSInteger _lineCount;
    CGFloat _space;
    PickerBrowserType _type;
    BOOL _allowEdit;
    BOOL _canDelete;
    UIViewController *_controller;
    NSString *_def;
    
}
@end

@implementation UploadImageView
- (instancetype)initWithFrame:(CGRect)frame controller:(UIViewController *)controller type:(PickerBrowserType)type allowEdit:(BOOL)allowEdit maxCount:(NSInteger)maxCount lineCount:(NSInteger)lineCount space:(CGFloat)space canEdit:(BOOL)canEdit defImage:(NSString *)def {
    self = [super initWithFrame:frame collectionViewLayout:[self getLayoutWithSpace:space frame:frame lineCount:lineCount canMove:NO]];
    if (self) {
        self.scrollEnabled = NO;
        self.backgroundColor = [UIColor whiteColor];
        self.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
        self.dataSource = self;
        self.delegate = self;
        self.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
        [self registerClass:[TZTestCell class] forCellWithReuseIdentifier:@"TZTestCell"];
        
        _selectImageItems = [NSMutableArray array];
        
        _controller = controller;
        _type = type;
        _allowEdit = allowEdit;
        _canEdit = canEdit;
        _canDelete = NO;
        _maxCount = maxCount;
        _lineCount = lineCount;
        _space = space;
        _def = def;
        _allowPickingGif = NO;
        _allowPickingOriginal = NO;
    }
    return self;
}

- (UICollectionViewFlowLayout *)getLayoutWithSpace:(CGFloat)space frame:(CGRect)frame lineCount:(NSInteger)lineCount canMove:(BOOL)canMove {
    if (canMove) {
        LxGridViewFlowLayout *layout = [[LxGridViewFlowLayout alloc] init];
        _itemWH = (frame.size.width - (lineCount - 1) * space) / lineCount;
        layout.itemSize = CGSizeMake(_itemWH, _itemWH);
        layout.minimumInteritemSpacing = space;
        layout.minimumLineSpacing = space;
        return layout;
    }
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    _itemWH = (frame.size.width - (lineCount - 1) * space) / lineCount;
    layout.itemSize = CGSizeMake(_itemWH, _itemWH);
    layout.minimumInteritemSpacing = space;
    layout.minimumLineSpacing = space;
    return layout;
}

- (void)reloadWithImages:(NSArray *)array {
    [_selectImageItems removeAllObjects];
    [_selectImageItems addObjectsFromArray:array];
    [self reloadData];
}

- (void)reloadData {
    [super reloadData];
    CGRect frame = self.frame;
    NSInteger count = _selectImageItems.count + (_selectImageItems.count < _maxCount && _canEdit ? 1 : 0);
    frame.size.height = _itemWH + ((count - 1) / _lineCount) * (_itemWH + _space);
    self.frame = frame;
    self.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.contentSize = CGSizeMake(0, frame.size.height);
    if (_didChangeFrame) {
        _didChangeFrame(self);
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _selectImageItems.count + (_selectImageItems.count < _maxCount && _canEdit ? 1 : 0);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    TZTestCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TZTestCell" forIndexPath:indexPath];
    cell.videoImageView.hidden = YES;
    if (indexPath.row == _selectImageItems.count) {
        cell.imageView.image = [UIImage imageNamed:_def && _def.length ? _def : @"AlbumAddBtn.png"];
        cell.deleteBtn.hidden = YES;
        cell.gifLable.hidden = YES;
    } else {
        PhotoItem *item = _selectImageItems[indexPath.row];
        if (item.image) {
            cell.imageView.image = item.image;
        }else {
            //cell.imageView.url = item.url;
        }
        cell.asset = item.asset;
        cell.deleteBtn.hidden = NO;
    }
    cell.gifLable.hidden = !_allowPickingGif;
    cell.deleteBtn.hidden = !_canDelete;
    cell.deleteBtn.tag = indexPath.row;
    [cell.deleteBtn addTarget:self action:@selector(deleteBtnClik:) forControlEvents:UIControlEventTouchUpInside];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (!_canEdit) return;
    if (_beginAdd) {
        _beginAdd();
    }
    if (indexPath.row == _selectImageItems.count) {
        __weak typeof(self) weak = self;
        _imagePickerBrowser = [[ImagePickerBrowser alloc] initWithController:_controller type:_type allowEdit:_allowEdit maxCount:_maxCount selectedImages:_selectImageItems isSelectOriginalPhoto:_isSelectOriginalPhoto complete:^(NSArray<PhotoItem *> *images, BOOL isSelectOriginalPhoto) {
            weak.isSelectOriginalPhoto = isSelectOriginalPhoto;
            [weak selectFinish:images];
        }];
    } else { // preview photos or video / 预览照片或者视频
        PhotoItem *item = _selectImageItems[indexPath.row];
        id asset = item.asset;
        BOOL isVideo = NO;
        if ([asset isKindOfClass:[PHAsset class]]) {
            PHAsset *phAsset = asset;
            isVideo = phAsset.mediaType == PHAssetMediaTypeVideo;
        } else if ([asset isKindOfClass:[ALAsset class]]) {
            ALAsset *alAsset = asset;
            isVideo = [[alAsset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo];
        }
        if ([[asset valueForKey:@"filename"] containsString:@"GIF"] && _allowPickingGif) {
            TZGifPhotoPreviewController *vc = [[TZGifPhotoPreviewController alloc] init];
            TZAssetModel *model = [TZAssetModel modelWithAsset:asset type:TZAssetModelMediaTypePhotoGif timeLength:@""];
            vc.model = model;
            [_controller presentViewController:vc animated:YES completion:nil];
        } else if (isVideo) { // perview video / 预览视频
            TZVideoPlayerController *vc = [[TZVideoPlayerController alloc] init];
            TZAssetModel *model = [TZAssetModel modelWithAsset:asset type:TZAssetModelMediaTypeVideo timeLength:@""];
            vc.model = model;
            [_controller presentViewController:vc animated:YES completion:nil];
        } else { // preview photos / 预览照片
            
            /*NSMutableArray *selectedAssets = [NSMutableArray array];
            NSMutableArray *selectedPhotos = [NSMutableArray array];
            for (ImagePickerItem *item in _selectImageItems) {
                [selectedAssets addObject:item.asset];
                [selectedPhotos addObject:item.image];
            }
            __weak typeof(self) weak = self;
            TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithSelectedAssets:selectedAssets selectedPhotos:selectedPhotos index:indexPath.row];
            imagePickerVc.maxImagesCount = _maxCount;
            imagePickerVc.allowPickingOriginalPhoto = _allowPickingOriginal;
            imagePickerVc.isSelectOriginalPhoto = _isSelectOriginalPhoto;
            [imagePickerVc setDidFinishPickingPhotosHandle:^(NSArray<UIImage *> *photos, NSArray *assets, BOOL isSelectOriginalPhoto) {
                NSMutableArray *array = [NSMutableArray array];
                for (int i = 0; i < MIN(photos.count, assets.count); i++) {
                    ImagePickerItem *item = [[ImagePickerItem alloc] init];
                    item.image = photos[i];
                    item.asset = assets[i];
                    [array addObject:item];
                }
                weak.isSelectOriginalPhoto = isSelectOriginalPhoto;
                [weak selectFinish:array];
            }];
            [_controller presentViewController:imagePickerVc animated:YES completion:nil];*/
        }
    }
}

- (void)closePhotoBrowser {
    
}

- (void)selectFinish:(NSArray *)items {
    for (PhotoItem *item in items) {
        for (PhotoItem *tempItem in _selectImageItems) {
            if ([item.asset isEqual:tempItem.asset]) {
                if (tempItem.url && tempItem.url.length > 0) {
                    item.url = tempItem.url;
                    item.ID = tempItem.ID;
                }
                break;
            }
        }
    }
    [_selectImageItems removeAllObjects];
    [_selectImageItems addObjectsFromArray:items];
    if (_addFinish) {
        _addFinish(_selectImageItems);
    }else {
        [self reloadData];
    }
}

#pragma mark - LxGridViewDataSource

/// 以下三个方法为长按排序相关代码
- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.item < _selectImageItems.count;
}

- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)sourceIndexPath canMoveToIndexPath:(NSIndexPath *)destinationIndexPath {
    return (sourceIndexPath.item < _selectImageItems.count && destinationIndexPath.item < _selectImageItems.count);
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)sourceIndexPath didMoveToIndexPath:(NSIndexPath *)destinationIndexPath {
    PhotoItem *item = _selectImageItems[sourceIndexPath.item];
    [_selectImageItems removeObjectAtIndex:sourceIndexPath.item];
    [_selectImageItems insertObject:item atIndex:destinationIndexPath.item];
    
    [self reloadData];
}

- (void)deleteBtnClik:(UIButton *)sender {
    [_selectImageItems removeObjectAtIndex:sender.tag];
    __weak typeof(self) weak = self;
    [self performBatchUpdates:^{
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:sender.tag inSection:0];
        [weak deleteItemsAtIndexPaths:@[indexPath]];
        if (_selectImageItems.count == _maxCount - 1) {
            [weak insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:_selectImageItems.count inSection:0]]];
        }
    } completion:^(BOOL finished) {
        [weak reloadData];
    }];
}

@end
