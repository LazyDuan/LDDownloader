//
//  ViewController.m
//  LDDownloadManager
//
//  Created by LazyDuan duan on 2020/6/20.
//  Copyright © 2020 LazyDuan. All rights reserved.
//

#import "ViewController.h"
#import "LDDownloadManager.h"
#define RGBCOLOR(r, g, b)       [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:1]
@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *downloadButton;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (copy, nonatomic) NSString *url;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.url = @"http://dldir1.qq.com/qqfile/QQforMac/QQ_V5.4.0.dmg";
    self.progressView.progress = [[LDDownloadManager sharedInstance] progress:self.url];
    [self.downloadButton addTarget:self action:@selector(button_Click:) forControlEvents:UIControlEventTouchUpInside];
}
- (void)button_Click:(UIButton *)button{
    [[LDDownloadManager sharedInstance] download:self.url progress:^(NSInteger receivedSize, NSInteger expectedSize, CGFloat progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressView.progress = progress;
            NSLog(@"progress==%f",progress);
        });
    } state:^(FileDownloadState state) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshButtonWithDownloadState:state];
        });
    } completionHandler:^(NSString * filePath, NSError * error) {
        
    }];
}
- (void)refreshButtonWithDownloadState:(FileDownloadState)state{
    switch (state) {
        case FileDownloadStart:
        {
            [self.downloadButton setTitle:@"暂停" forState:UIControlStateNormal];
            [self.downloadButton setBackgroundColor:RGBCOLOR(255, 159, 97)];
        }
            break;
        case FileDownloadSuspended:
        {
                [self.downloadButton setTitle:@"继续" forState:UIControlStateNormal];
        }
        case FileDownloadFailed:
        {
            [self.downloadButton setTitle:@"下载" forState:UIControlStateNormal];
        }
            break;
        case FileDownloadCompleted:{
            [self.downloadButton setTitle:@"已下载" forState:UIControlStateNormal];
            [self.downloadButton setBackgroundColor:RGBCOLOR(187, 187, 187)];
        }
            break;
        default:
            break;
    }
}
- (IBAction)deleteFile:(id)sender {
    [[LDDownloadManager sharedInstance] deleteFileWithUrl:self.url];
    self.progressView.progress = 0;
    [self refreshButtonWithDownloadState:FileDownloadFailed];
}


@end
