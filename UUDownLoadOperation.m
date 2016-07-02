//
//  UUDownLoadOperation.m
//  AFDownLoadDemo
//
//  Created by 尤锐 on 16/1/21.
//  Copyright (c) 2016年 尤锐. All rights reserved.
//

#import "UUDownLoadOperation.h"

@implementation UUDownLoadOperation
- (void)downloadWithURL:(NSString *)urlStr cachePath:(NSString *(^)(void))cacheBlock progress:(ProgressValueChanged)progressBlock success:(DownloadSuccess)successBlock failed:(DownloadFailed)failure
{
    // 记录缓存位置的block
    if (cacheBlock != nil) {
        self.cachePath = cacheBlock;
    }
    // 获取本地缓存文件的数据长度
    long long cacheLength = [UUDownLoadOperation cacheFileWithPath:self.cachePath()];
    NSLog(@"CacheLenth:%lld",cacheLength);
    
    // 类方法创建一个请求体
    NSMutableURLRequest *request = [[self class] requestWithURL:[NSURL URLWithString:urlStr] range:cacheLength];
    
    // 实例化AF的请求任务
    self.requestOpration = [[AFHTTPRequestOperation alloc]initWithRequest:request];
    
    //设置输出流加载
    [self.requestOpration setOutputStream:[NSOutputStream outputStreamToFileAtPath:self.cachePath() append:NO]];
    
    // 处理流写入AFHttpOperation.outStream
    [self readCacheToStreamWithPath:self.cachePath()];
    
    // 传递进度
    self.progressBlock = progressBlock;
    
    // 重写组装进度的block
    // 调用我自己的block
    [self.requestOpration setDownloadProgressBlock:[self getNewProgressBlockWithCatchLength:cacheLength]];
    if (successBlock != nil){
        _successBlock = successBlock;
    }
    
    if (failure != nil) {
        _failedBlock = failure;
    }
    
    
    // 设置af的成功和失败的回调
    [self.requestOpration setCompletionBlockWithSuccess:successBlock failure:failure];
    
    // 开启任务
    [self.requestOpration start];
}

// 重载进度
- (ProgressValueChanged)getNewProgressBlockWithCatchLength:(long long)cacheLength{
    // 为防止内存泄露,将自己转化为若指针
    __weak typeof (self)newSelf = self;
    ProgressValueChanged newProgress = ^(NSUInteger bytesRead,long long totalBytesRead,long long totalBytesExpectedToRead){
        NSData *data = [NSData dataWithContentsOfFile:self.cachePath()];
        [self.requestOpration setValue:data forKey:@"responseData"];
        
        newSelf.progressBlock(bytesRead,totalBytesRead + cacheLength,totalBytesExpectedToRead + cacheLength);
    };
    return newProgress;
}

// 处理流
// 读取本地的缓存写入AFHttpOpration.outPutStream
- (void)readCacheToStreamWithPath:(NSString *)path{
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:path];
    NSData *currentData = [handle readDataToEndOfFile];
    if (currentData.length > 0) {
        // 打开流,写入数据
        [self.requestOpration.outputStream open];
        
        // 已经写入的长度,目前已经写入的长度
        NSInteger bytesWitten,bytesWittenSoFar = 0;
        // 已经保存的数据流长度
        NSInteger dataLength = currentData.length;
        // 已经保存的数据位数
        const uint8_t *dataBytes = currentData.bytes;
        while (bytesWittenSoFar != dataLength) {
            //dataBytes 0010 0101 0101
            // write:maxLength:
            // prama:uint8_t *:传入写入的流
            //       maxLength:写入的总长度
            // return:写入的长度
            bytesWitten = [self.requestOpration.outputStream write:&dataBytes[bytesWittenSoFar] maxLength:dataLength - bytesWittenSoFar];
            // 容错,括弧中的值是0，立即打印一行报错
            assert(bytesWitten != 0);
            
            // 判断写入是否有错:有错返回-1
            if (bytesWitten == -1) {
                break;
            }else{
                bytesWittenSoFar += bytesWitten;
            }
        }
    }
}

+ (long long)cacheFileWithPath:(NSString *)path{
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:path];
    NSData *contentData = [handle readDataToEndOfFile];
    
    return contentData?contentData.length:0;
}

+ (NSMutableURLRequest *)requestWithURL:(NSURL *)url range:(long long)length{

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    // 设置关闭系统的缓存
    request.cachePolicy = NSURLRequestReloadIgnoringCacheData;
    // 设置链接等待超时
    request.timeoutInterval = 5*60;
    
    if (length > 0) {
        [request setValue:[NSString stringWithFormat:@"bytes=%lld-",length] forHTTPHeaderField:@"RANGE"];
    }
    return request;
}

- (void) pause
{
    if (!_isPause) {
        [self.requestOpration pause];
        _isPause = YES;
        long long cacheLenth = [UUDownLoadOperation cacheFileWithPath:self.cachePath()];
        // 暂停读取data 从文件中获取当前的长度
        // 获取当前stream里面的文件大小
        cacheLenth = [[self.requestOpration.outputStream propertyForKey:NSStreamFileCurrentOffsetKey] unsignedLongLongValue];
        
        [self.requestOpration setValue:@"0" forKey:@"totalBytesRead"];
        // 重组进度的block
        [self.requestOpration setDownloadProgressBlock:[self getNewProgressBlockWithCatchLength:cacheLenth]];
    }
}

- (void) resume{
    if (_isPause) {
        [self.requestOpration resume];
        _isPause = NO;
        
    }
}

@end
