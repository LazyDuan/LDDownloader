//
//  LDDownloadManager.m
//  OCDemo
//
//  Created by LazyDuan duan on 2020/6/19.
//  Copyright © 2020 LazyDuan. All rights reserved.
//


#import "LDDownloadManager.h"

@interface LDDownloadManager()<NSCopying,NSURLSessionDelegate>
@property (nonatomic, copy) NSString *cachePath;
@property (nonatomic, copy) NSString *fileSizePath;

/** 保存所有任务(注：用下载地址/后作为key) */
@property (nonatomic, strong) NSMutableDictionary *tasks;
/** 保存所有下载相关信息 */
@property (nonatomic, strong) NSMutableDictionary *sessionModels;

@property (strong, nonatomic, nonnull) NSOperationQueue *downloadQueue;
@end

@implementation LDDownloadManager

#pragma mark - LifeCycle
static LDDownloadManager *_downloadManager;

+ (instancetype)allocWithZone:(struct _NSZone *)zone{
    return [self sharedInstance];
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone{
    return self;
}

+ (instancetype)sharedInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _downloadManager = [[super allocWithZone:NULL] init];
        _downloadManager.cachePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"FileCache"];
        _downloadManager.fileSizePath = [_downloadManager.cachePath stringByAppendingPathComponent:@"FileSize.plist"];
        _downloadManager.tasks = [NSMutableDictionary dictionary];
        _downloadManager.sessionModels = [NSMutableDictionary dictionary];
    });
    
    return _downloadManager;
}

#pragma mark - Public
/**
 *  设置下载回调
 */
- (void)setBlock:(NSString *)url progress:(void(^)(NSInteger receivedSize, NSInteger expectedSize, CGFloat progress))progress state:(void(^)(FileDownloadState state))state completionHandler:( void (^)(NSString * filePath, NSError * error))completionHandler{
    NSURLSessionDataTask *task = [self getTask:url];
    if (task) {
        LDDownloadModel *sessionModel = [self getSessionModel:task.taskIdentifier];
        sessionModel.progress = progress;
        sessionModel.state = state;
        sessionModel.completionHandler = completionHandler;
        [self.sessionModels setValue:sessionModel forKey:@(task.taskIdentifier).stringValue];
    }
}
/**
 *  开启任务下载资源
 */
- (void)download:(NSString *)url progress:(void (^)(NSInteger, NSInteger, CGFloat))progress state:(void(^)(FileDownloadState state))state completionHandler:(nullable void (^)(NSString * filePath, NSError * error))completionHandler{
    if (!url) return;
    if ([self fileDownloadStateWithUrl:url]== FileDownloadCompleted) {
        state(FileDownloadCompleted);
        NSLog(@"----该资源已下载完成");
        return;
    }
    // 暂停
    if ([self.tasks valueForKey:[self fileNameFromUrl:url]]) {
        [self handle:url];
        return;
    }
    
    // 创建缓存目录文件
    [self createCacheDirectory];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[[NSOperationQueue alloc] init]];
    
    // 创建流
    NSOutputStream *stream = [NSOutputStream outputStreamToFileAtPath:[self filePathWithUrl:url] append:YES];
    
    // 创建请求
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    // 设置请求头
    NSString *range = [NSString stringWithFormat:@"bytes=%zd-", [self downloadFileLengthWithUrl:url]];
    [request setValue:range forHTTPHeaderField:@"Range"];
    
    // 创建一个Data任务
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request];
    NSUInteger taskIdentifier = arc4random() % ((arc4random() % 10000 + arc4random() % 10000));
    [task setValue:@(taskIdentifier) forKeyPath:@"taskIdentifier"];
    
    // 保存任务
    [self.tasks setValue:task forKey:[self fileNameFromUrl:url]];
    
    LDDownloadModel *sessionModel = [[LDDownloadModel alloc] init];
    sessionModel.url = url;
    sessionModel.progress = progress;
    sessionModel.state = state;
    sessionModel.completionHandler = completionHandler;
    sessionModel.stream = stream;
    [self.sessionModels setValue:sessionModel forKey:@(task.taskIdentifier).stringValue];
    
    [self start:url];
}

/**
 *  查询该资源的下载进度值
 */
- (CGFloat)progress:(NSString *)url{
    return [self fileTotalLength:url] == 0 ? 0.0 : 1.0 * [self downloadFileLengthWithUrl:url] /  [self fileTotalLength:url];
}

- (FileDownloadState)fileDownloadStateWithUrl:(NSString *)url{
    if ([self fileTotalLength:url]) {
        if([self downloadFileLengthWithUrl:url] == [self fileTotalLength:url]){
            return FileDownloadCompleted;
        }else{
            return FileDownloadSuspended;
        }
        
    }
    return FileDownloadNone;
}
- (NSString *)downloadFilePathWithUrl:(NSString *)url{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *filePath = [self filePathWithUrl:url];
    if ([fileManager fileExistsAtPath:filePath]) {
        return filePath;
    }
    return @"";
}
/**
 *  获取该资源总大小
 */
- (NSInteger)fileTotalLength:(NSString *)url{
    return [[NSDictionary dictionaryWithContentsOfFile:self.fileSizePath][[self fileNameFromUrl:url]] integerValue];
}
/**
 *  删除该资源
 */
- (void)deleteFileWithUrl:(NSString *)url{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *filePath = [self filePathWithUrl:url];
    if ([fileManager fileExistsAtPath:filePath]) {
        
        // 删除沙盒中的资源
        [fileManager removeItemAtPath:filePath error:nil];
        // 删除任务
        [self.tasks removeObjectForKey:[self fileNameFromUrl:url]];
        [self.sessionModels removeObjectForKey:@([self getTask:url].taskIdentifier).stringValue];
        // 删除资源总长度
        if ([fileManager fileExistsAtPath:self.fileSizePath]) {
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:self.fileSizePath];
            [dict removeObjectForKey:[self fileNameFromUrl:url]];
            [dict writeToFile:self.fileSizePath atomically:YES];
            
        }
    }
}

/**
 *  清空所有下载资源
 */
- (void)deleteAllFile{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:self.cachePath]) {
        
        // 删除任务
        [[self.tasks allValues] makeObjectsPerformSelector:@selector(cancel)];
        [self.tasks removeAllObjects];
        
        for (LDDownloadModel *sessionModel in [self.sessionModels allValues]) {
            [sessionModel.stream close];
        }
        [self.sessionModels removeAllObjects];
        
        // 删除沙盒中所有资源
        [fileManager removeItemAtPath:self.cachePath error:nil];
        // 删除资源总长度
        if ([fileManager fileExistsAtPath:self.fileSizePath]) {
            [fileManager removeItemAtPath:self.fileSizePath error:nil];
        }
    }
}

#pragma mark - Private
/**
 *  创建缓存目录文件
 */
- (void)createCacheDirectory{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:self.cachePath]) {
        [fileManager createDirectoryAtPath:self.cachePath withIntermediateDirectories:YES attributes:nil error:NULL];
    }
}

- (NSString *)fileNameFromUrl:(NSString *)url{
    return [[url componentsSeparatedByString:@"/"] lastObject];
}
- (NSString *)filePathWithUrl:(NSString *)url{
    return [self.cachePath stringByAppendingPathComponent:[self fileNameFromUrl:url]];
}
- (NSInteger)downloadFileLengthWithUrl:(NSString *)url{
    return [[[NSFileManager defaultManager] attributesOfItemAtPath:[self filePathWithUrl:url] error:nil][NSFileSize] integerValue];
}

- (void)handle:(NSString *)url{
    NSURLSessionDataTask *task = [self getTask:url];
    if (task.state == NSURLSessionTaskStateRunning) {
        [self pause:url];
    } else {
        [self start:url];
    }
}

/**
 *  开始下载
 */
- (void)start:(NSString *)url{
    NSURLSessionDataTask *task = [self getTask:url];
    [task resume];
    
    [self getSessionModel:task.taskIdentifier].state(FileDownloadStart);
}

/**
 *  暂停下载
 */
- (void)pause:(NSString *)url{
    NSURLSessionDataTask *task = [self getTask:url];
    [task suspend];
    [self getSessionModel:task.taskIdentifier].state(FileDownloadSuspended);
}
/**
 *  根据url获得对应的下载任务
 */
- (NSURLSessionDataTask *)getTask:(NSString *)url{
    return (NSURLSessionDataTask *)[self.tasks valueForKey:[self fileNameFromUrl:url]];
}

/**
 *  根据url获取对应的下载信息模型
 */
- (LDDownloadModel *)getSessionModel:(NSUInteger)taskIdentifier{
    return (LDDownloadModel *)[self.sessionModels valueForKey:@(taskIdentifier).stringValue];
}
#pragma mark NSURLSessionDataDelegate
/**
 * 接收到响应
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler{
    
    LDDownloadModel *sessionModel = [self getSessionModel:dataTask.taskIdentifier];
    
    // 打开流
    [sessionModel.stream open];
    
    // 获得服务器这次请求 返回数据的总长度
    NSInteger totalLength = [response.allHeaderFields[@"Content-Length"] integerValue] + [self downloadFileLengthWithUrl:sessionModel.url];
    sessionModel.totalLength = totalLength;
    sessionModel.mimeType = response.allHeaderFields[@"Content-Type"];
    
    // 存储总长度
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:self.fileSizePath];
    if (dict == nil) dict = [NSMutableDictionary dictionary];
    dict[[self fileNameFromUrl:sessionModel.url]] = @(totalLength);
    [dict writeToFile:self.fileSizePath atomically:YES];
    
    // 接收这个请求，允许接收服务器的数据
    completionHandler(NSURLSessionResponseAllow);
}

/**
 * 接收到服务器返回的数据
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{
    LDDownloadModel *sessionModel = [self getSessionModel:dataTask.taskIdentifier];
    
    // 写入数据
    [sessionModel.stream write:data.bytes maxLength:data.length];
    
    // 下载进度
    NSUInteger receivedSize = [self downloadFileLengthWithUrl:sessionModel.url];
    NSUInteger expectedSize = sessionModel.totalLength;
    CGFloat progress = 1.0 * receivedSize / expectedSize;
    
    sessionModel.progress(receivedSize, expectedSize, progress);
}

/**
 * 请求完毕（成功|失败）
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    LDDownloadModel *sessionModel = [self getSessionModel:task.taskIdentifier];
    if (!sessionModel) return;
    if ([self fileDownloadStateWithUrl:sessionModel.url]==FileDownloadCompleted) {
        // 下载完成
        sessionModel.state(FileDownloadCompleted);
    } else if (error){
        // 下载失败
        sessionModel.state(FileDownloadFailed);
    }
    sessionModel.completionHandler([self filePathWithUrl:sessionModel.url], error);
    
    // 关闭流
    [sessionModel.stream close];
    sessionModel.stream = nil;
    
    // 清除任务
    [self.tasks removeObjectForKey:[self fileNameFromUrl:sessionModel.url]];
    [self.sessionModels removeObjectForKey:@(task.taskIdentifier).stringValue];
    
}

@end
