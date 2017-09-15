//
//  ViewController.m
//  WKImagePick
//
//  Created by jeaner on 2017/9/12.
//  Copyright © 2017年 Jeaner. All rights reserved.
//

#import "ViewController.h"
#import "ImagePickerBrowser.h"

@interface ViewController ()<UIActionSheetDelegate>
{
    UIActionSheet *myActionSheet;
    ImagePickerBrowser *_browser;
    NSString* filePath;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor=[UIColor blueColor];
    
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    //在这里呼出下方菜单按钮项
    myActionSheet = [[UIActionSheet alloc]
                     initWithTitle:nil
                     delegate:self
                     cancelButtonTitle:@"取消"
                     destructiveButtonTitle:nil
                     otherButtonTitles:
                     @"使用相机"
                     ,@"本地相册"
                     ,@"本地视频"
                     ,nil];
    
    [myActionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    //呼出的菜单按钮点击后的响应
    if (buttonIndex == myActionSheet.cancelButtonIndex)
    {
        NSLog(@"取消");
    }
    
    switch (buttonIndex)
    {
        case 0:  //打开照相机拍照
            //[self takePhoto];
            break;
            
        case 1:  //打开本地相册
            [self LocalPhoto];
            break;
    }
}


-(void)LocalPhoto
{
    
    __weak typeof(self) weak = self;
    _browser = [[ImagePickerBrowser alloc] initWithController:self type:PickerBrowserAlbum allowEdit:NO maxCount:1 selectedImages:nil isSelectOriginalPhoto:YES complete:^(NSArray<PhotoItem *> *images, BOOL isSelectOriginalPhoto) {
        PhotoItem *item = [images firstObject];
        [weak chooseImageFinish:item.image];
    }];
}

- (void)chooseImageFinish:(UIImage *)image {
    NSData *data = [self representationImage:image];
    
    //图片保存的路径
    //这里将图片放在沙盒的documents文件夹中
    NSString * DocumentsPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    
    
    //文件管理器
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    //把刚刚图片转换的data对象拷贝至沙盒中 并保存为image.png
    [fileManager createDirectoryAtPath:DocumentsPath withIntermediateDirectories:YES attributes:nil error:nil];
    [fileManager createFileAtPath:[DocumentsPath stringByAppendingString:@"/image.png"] contents:data attributes:nil];
    
    //得到选择后沙盒中图片的完整路径
    filePath = [[NSString alloc]initWithFormat:@"%@%@",DocumentsPath,  @"/image.png"];
    
    
    //    [self uploadPhoto] ;
}

- (NSData *)representationImage:(UIImage *)image
{
    NSData *data = UIImageJPEGRepresentation(image,0.8);
    for (int i = 0; i < 4; i++)
    {
        if (data.length < 500*1024) {
            break;
        }
        
        UIImage *newImage = [UIImage imageWithData:data];
        data = UIImageJPEGRepresentation(newImage,0.8);
    }
    return data;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
