//
//  ViewController.m
//  QiNiuMulitUploadDemo
//
//  Created by Ethan on 2017/10/9.
//  Copyright © 2017年 Ethan. All rights reserved.
//

#import "ViewController.h"
#import <Qiniu/QiniuSDK.h>
#import <AFNetworking/AFNetworking.h>

@interface ViewController ()

@property (nonatomic, strong) NSArray *uploadArray;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	UIImage *image0 = [UIImage imageNamed:@"0.jpg"];
	UIImage *image1 = [UIImage imageNamed:@"1.jpg"];
	UIImage *image2 = [UIImage imageNamed:@"2.jpg"];
	
	self.uploadArray = [NSArray arrayWithObjects:image0,image1,image2, nil];
	
}
- (IBAction)uploadButton:(UIButton *)sender {
	
	[self upload];
	
}

- (void)upload{
	
	dispatch_queue_t queue = dispatch_queue_create("com.ethan.uploadDemoTest", DISPATCH_QUEUE_SERIAL);

	QNUploadManager *uploadManager = [[QNUploadManager alloc]init];

	for (int i = 0; i < _uploadArray.count; i ++) {
		
		//串行异步
		dispatch_async(queue, ^{
			
			dispatch_semaphore_t sema = dispatch_semaphore_create(0);//创建信号
			NSString *url = [NSString stringWithFormat:@"http://your get upload token api address"];
			//获取上传token
			AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
			manager.requestSerializer = [AFHTTPRequestSerializer serializer];
			manager.requestSerializer.timeoutInterval = 20;
			[manager GET:url
			  parameters:nil
				progress:^(NSProgress * _Nonnull downloadProgress) {
					
				}success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
					
					NSString *token = [responseObject objectForKey:@"token"];
					UIImage *image = [_uploadArray objectAtIndex:i];
					self.imageView.image = image;
					NSLog(@"串行同步 %d   %@  ====  %@",i,[NSThread currentThread], token);
					
					NSData *data = UIImageJPEGRepresentation(image, 0.5);
					NSString *key = [NSString stringWithFormat:@"%.0f_%d", [[NSDate date] timeIntervalSince1970], arc4random()%99999];
					
					QNUploadOption *opt = [[QNUploadOption alloc]initWithMime:nil
															  progressHandler:^(NSString *key, float percent) {
																  
																  NSLog(@"key %@  == %f%@",key, percent,@"%");
																  
																  
																  dispatch_async(dispatch_get_main_queue(), ^{
																	  
																	  self.progressView.progress = percent;
																	  
																  });
																  
															  } params:nil checkCrc:YES cancellationSignal:nil];
					
					[uploadManager putData:data key:key token:token
							complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
								if (info.isOK) {
									
									dispatch_semaphore_signal(sema);//信号 +1
									if (i + 1 == self.uploadArray.count) {
										
										//上传完成
										NSLog(@"上传完成");
										return ;
									}
									
								}
								
							} option:opt];
					
				} failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
					
				}];
			
			
			dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);//信号等待
		});
	}
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}


@end
