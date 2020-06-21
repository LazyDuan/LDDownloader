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
 *  @param progressBlock 回调下载进度
 *  @param stateBlock    下载状态
 */
- (void)setBlock:(NSString *)url progress:(void(^)(NSInteger receivedSize, NSInteger expectedSize, CGFloat progress))progressBlock state:(void(^)(DownloadState state))stateBlock;
/**
 *  开启任务下载资源
 *
 *  @param url           下载地址
 *  @param progressBlock 回调下载进度
 *  @param stateBlock    下载状态
 */
- (void)download:(NSString *)url progress:(void(^)(NSInteger receivedSize, NSInteger expectedSize, CGFloat progress))progressBlock state:(void(^)(DownloadState state))stateBlock;

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
 *  判断该资源是否下载完成
 *
 *  @param url 下载地址
 *
 *  @return YES: 完成
 */
- (BOOL)isCompletion:(NSString *)url;

/**
 *  删除该资源
 *
 *  @param url 下载地址
 */
- (void)deleteFile:(NSString *)url;

/**
 *  清空所有下载资源
 */
- (void)deleteAllFile;

@end

NS_ASSUME_NONNULL_END
