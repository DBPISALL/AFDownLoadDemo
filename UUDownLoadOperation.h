//
//  UUDownLoadOperation.h
//  AFDownLoadDemo
//
//  Created by 尤锐 on 16/1/21.
//  Copyright (c) 2016年 尤锐. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"
typedef void(^DownloadSuccess)(AFHTTPRequestOperation *operation,id responseObject);
typedef void(^DownloadFailed)(AFHTTPRequestOperation *operation,NSError *error);

typedef void(^ProgressValueChanged) (NSUInteger bytesRead,long long totalBytesRead,long long totalBytesExpectedToRead);

@interface UUDownLoadOperation : NSObject


@property (strong, nonatomic) NSURL *url;

// 网络请求的任务
@property (strong, nonatomic)AFHTTPRequestOperation *requestOpration;

@property (copy)DownloadSuccess successBlock;
@property (copy)DownloadFailed failedBlock;
@property (copy)ProgressValueChanged progressBlock;

// 下载位置
@property (nonatomic,copy) NSString *(^cachePath)(void);

- (void)downloadWithURL:(NSString *)urlStr cachePath:(NSString *(^)(void))cacheBlock progress:(ProgressValueChanged)progressBlock success:(DownloadSuccess)successBlock failed:(DownloadFailed)failure;


@property (assign,readonly)BOOL isPause;
// 暂停
- (void)pause;
// 重启
- (void)resume;

@end
