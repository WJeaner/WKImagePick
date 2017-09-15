# WKImagePick

由于提交Git的关系  运行会出现文件丢失, 将缺失的文件,在文件夹里找到直接导入即可

这是一个可以编辑选中照片的封装库,一键调用,可以实现照片的马赛克,涂鸦,增加标题,修改尺寸以及旋转的功能
在这个demo中可以仿照一键调用
效果图贴了几次没贴上去,可以去我的博客看效果

使用方法:

先创建一个实例对象:[ImagePickerBrowser alloc]

然后调用initWithController的方法

举例如下

  ImagePickerBrowser  *browser = [[ImagePickerBrowser alloc] initWithController:self type:PickerBrowserAlbum allowEdit:NO 
  maxCount:1 selectedImages:nil isSelectOriginalPhoto:YES complete:^(NSArray<PhotoItem *> *images, BOOL isSelectOriginalPhoto) {
        
        //这里是修改后照片所执行的方法
        PhotoItem *item = [images firstObject];//拿到所做修改的图片
        [weak chooseImageFinish:item.image];//执行一个你需要的方法
    
  }];
