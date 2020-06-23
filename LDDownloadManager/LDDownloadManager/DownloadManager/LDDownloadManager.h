//
//  LDDownloadManager.h
//  OCDemo
//
//  Created by LazyDuan duan on 2020/6/19.
//  Copyright © 2020 LazyDuan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LDDownloadModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface LDDownloadManager : NSObject
/**
 *  单例
 *
 *  @return 返回单例对象
 */
+ (instancetype)sharedInstance;
/**
 *  设置回调
 *
 *  @param url           下载地址
 *  @param progress  回调下载进度
 *  @param state    下载状态
 */
- (void)setBlock:(NSString *)url progress:(void(^)(NSInteger receivedSize, NSInteger expectedSize, CGFloat progress))progress state:(void(^)(FileDownloadState state))state completionHandler:( void (^)(NSString * filePath, NSError * error))completionHandler;
/**
 *  开启任务下载资源
 *
 *  @param url           下载地址
 *  @param progress 回调下载进度
 *  @param completionHandler    下载结果
 */
- (void)download:(NSString *)url progress:(void(^)(NSInteger receivedSize, NSInteger expectedSize, CGFloat progress))progress state:(void(^)(FileDownloadState state))state completionHandler:(nullable void (^)(NSString * filePath, NSError * error))completionHandler;

/**
 *  查询该资源的下载进度值
 *
 *  @param url 下载地址
 *
 *  @return 返回下载进度值
 */
- (CGFloat)progress:(NSString *)url;

/**
 *  获取该资源总大小
 *
 *  @param url 下载地址
 *
 *  @return 资源总大小
 */
- (NSInteger)fileTotalLength:(NSString *)url;


/**
 *  获取该资源下载状态
 *
 *  @param url 下载地址
 *
 *  @return 资源下载状态
 */
- (FileDownloadState)fileDownloadStateWithUrl:(NSString *)url;

/**
 *  获取该资源下载地址
 *
 *  @param url 下载地址
 *
 *  @return 资源下载地址
 */
- (NSString *)downloadFilePathWithUrl:(NSString *)url;

/**
 *  删除指定资源
 *
 *  @param url 下载地址
 */
- (void)deleteFileWithUrl:(NSString *)url;

/**
 *  清空所有下载资源
 */
- (void)deleteAllFile;

@end

NS_ASSUME_NONNULL_END
