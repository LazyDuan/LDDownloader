//
//  LDDownloadModel.h
//  OCDemo
//
//  Created by LazyDuan duan on 2020/6/19.
//  Copyright © 2020 LazyDuan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger,FileDownloadState) {
    FileDownloadStart     = 0,     /** 下载中 */
    FileDownloadSuspended = 1,     /** 下载暂停 */
    FileDownloadCompleted = 2,     /** 下载完成 */
    FileDownloadFailed    = 3,     /** 下载失败 */
    FileDownloadNone      = 4,     /** 未下载 */
    
};

@interface LDDownloadModel : NSObject

/** 流 */
@property (nonatomic, strong) NSOutputStream *stream;

/** 下载地址 */
@property (nonatomic, copy) NSString *url;

/** 获得服务器这次请求 返回数据的总长度 */
@property (nonatomic, assign) NSInteger totalLength;

/** 获得服务器这次请求 返回数据的类型 */
@property (nonatomic, assign) NSString *mimeType;

/** 下载进度 */
@property (nonatomic, copy) void(^progress)(NSInteger receivedSize, NSInteger expectedSize, CGFloat progress);
/** 下载状态 */
@property (nonatomic, copy) void(^state)(FileDownloadState state);
/** 下载结果 */
@property (nonatomic, copy) void (^completionHandler)(NSString * filePath, NSError * error);

@end

