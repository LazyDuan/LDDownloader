# LDDownloader
网络文件下载，使用NSURLSession支持断点续传

### 使用方法：

    [[LDDownloadManager sharedInstance] download:self.url progress:^(NSInteger receivedSize, NSInteger expectedSize, CGFloat progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressView.progress = progress;
            NSLog(@"progress==%f",progress);
        });
    } state:^(FileDownloadState state) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshButtonWithDownloadState:state];
        });
    } completionHandler:^(NSString * _Nonnull filePath, NSError * _Nonnull error) {
        
    }];
  
  
  如果喜欢，请帮忙点颗星星✨
