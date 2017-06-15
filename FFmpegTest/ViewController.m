//
//  ViewController.m
//  FFmpegTest
//
//  Created by vip-刘旭 on 2017/6/15.
//  Copyright © 2017年 vip-刘旭. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "avcodec.h"

@interface ViewController () <AVCaptureFileOutputRecordingDelegate>

@property (nonatomic, strong) AVCaptureMovieFileOutput *output;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //1.创建视频设备(摄像头前，后)
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    //2.初始化一个摄像头输入设备(first是后置摄像头，last是前置摄像头)
    AVCaptureDeviceInput *inputVideo = [AVCaptureDeviceInput deviceInputWithDevice:[devices firstObject] error:NULL];
    
    //3.创建麦克风设备
    AVCaptureDevice *deviceAudio = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    //4.初始化麦克风输入设备
    AVCaptureDeviceInput *inputAudio = [AVCaptureDeviceInput deviceInputWithDevice:deviceAudio error:NULL];
    
    //5.初始化一个movie的文件输出
    AVCaptureMovieFileOutput *output = [[AVCaptureMovieFileOutput alloc] init];
    self.output = output; //保存output，方便下面操作
    
    //6.初始化一个会话
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    
    //7.将输入输出设备添加到会话中
    if ([session canAddInput:inputVideo]) {
        [session addInput:inputVideo];
    }
    if ([session canAddInput:inputAudio]) {
        [session addInput:inputAudio];
    }
    if ([session canAddOutput:output]) {
        [session addOutput:output];
    }
    
    //8.创建一个预览涂层
    AVCaptureVideoPreviewLayer *preLayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
    //设置图层的大小
    preLayer.frame = self.view.bounds;
    //添加到view上
    [self.view.layer addSublayer:preLayer];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    //判断是否在录制,如果在录制，就停止，并设置按钮title
    if ([self.output isRecording]) {
        [self.output stopRecording];
        return;
    }
    
    //设置按钮的title
    
    //10.开始录制视频
    //设置录制视频保存的路径
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"myVidio.mov"];
    
    //转为视频保存的url
    NSURL *url = [NSURL fileURLWithPath:path];
    
    //开始录制,并设置控制器为录制的代理
    [self.output startRecordingToOutputFileURL:url recordingDelegate:self];
    
}

#pragma  mark - AVCaptureFileOutputRecordingDelegate
//录制完成代理
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    NSLog(@"完成录制,可以自己做进一步的处理");
}


@end
