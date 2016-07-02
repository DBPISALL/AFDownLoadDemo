//
//  ViewController.m
//  AFDownLoadDemo
//
//  Created by 尤锐 on 16/1/21.
//  Copyright (c) 2016年 尤锐. All rights reserved.
//

#import "ViewController.h"
#import "UUDownLoadOperation.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIImageView *iamgeView;

@property (strong,nonatomic)UUDownLoadOperation *operation;

- (IBAction)pressStart:(UIButton *)sender;

@end

@implementation ViewController

- (IBAction)pressStart:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
        // 开始
        // 如果是暂停，就让它重启
        if (_operation.isPause){
            [_operation resume];
        }else{
            // 启动一个新的
            [self startDownLoad];
        }
    }else{
        // 暂停
        [_operation pause];
    }
}

- (void)startDownLoad{
    
    _operation = [[UUDownLoadOperation alloc]init];
    NSString *path = [NSString stringWithFormat:@"%@/Documents/tmp",NSHomeDirectory()];
    
    
    [_operation downloadWithURL:@"http://pic9.nipic.com/20100812/3289547_144304019987_2.jpg" cachePath:^NSString *{
        
        return path;
        
    } progress:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        
        float progress = 1.0f * totalBytesRead/totalBytesExpectedToRead;
        _progressView.progress = progress;
        _progressLabel.text = [NSString stringWithFormat:@"%.2f%%",progress * 100];
        UIImage *image = [UIImage imageWithData:_operation.requestOpration.responseData];
        _iamgeView.image = image;
        
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        UIImage *image = [UIImage imageWithData:_operation.requestOpration.responseData];
        _iamgeView.image = image;
        
    } failed:^(AFHTTPRequestOperation *operation, NSError *error) {
        
    }];

}

@end
