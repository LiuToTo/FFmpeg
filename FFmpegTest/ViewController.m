//
//  ViewController.m
//  FFmpegTest
//
//  Created by vip-刘旭 on 2017/6/15.
//  Copyright © 2017年 vip-刘旭. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "H264EncodeManager.h"
#import <libavcodec/avcodec.h>
#import <libavformat/avformat.h>
#import <libavutil/opt.h>
#import <libavutil/imgutils.h>
#import <libswscale/swscale.h>

@interface ViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>
{
    AVCodec * _H264Codec;
    AVCodecContext *_codecContext;
    H264EncodeManager *_encoder;
    AVCaptureSession *_session;
}

@property (nonatomic, strong) AVCaptureVideoDataOutput *output;

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
    AVCaptureVideoDataOutput *avCaptureVideoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    NSDictionary *settings = [[NSDictionary alloc] initWithObjectsAndKeys:
                              [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey,
                              nil];
    
    
    
    avCaptureVideoDataOutput.videoSettings = settings;
    avCaptureVideoDataOutput.alwaysDiscardsLateVideoFrames = YES;
    
    /*We create a serial queue to handle the processing of our frames*/
    dispatch_queue_t queue = dispatch_queue_create("myQueue", NULL);
    [avCaptureVideoDataOutput setSampleBufferDelegate:self queue:queue];
    _output = avCaptureVideoDataOutput;
    
    //6.初始化一个会话
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    
    //7.将输入输出设备添加到会话中
    if ([session canAddInput:inputVideo]) {
        [session addInput:inputVideo];
    }
    if ([session canAddInput:inputAudio]) {
        [session addInput:inputAudio];
    }
    if ([session canAddOutput:_output]) {
        [session addOutput:avCaptureVideoDataOutput];
    }
    
    //8.创建一个预览涂层
    AVCaptureVideoPreviewLayer *preLayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
    //设置图层的大小
    preLayer.frame = self.view.bounds;
    //添加到view上
    [self.view.layer addSublayer:preLayer];
    
    _encoder = [H264EncodeManager new];
    _session = session;
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [_session startRunning];
}

#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);

    
    if(CVPixelBufferLockBaseAddress(imageBuffer, 0) == kCVReturnSuccess)
    {
        CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        CMTime duration = CMSampleBufferGetDuration(sampleBuffer);
        // Get the number of bytes per row for the plane pixel buffer
        
        size_t width = CVPixelBufferGetWidth(imageBuffer);
        size_t height = CVPixelBufferGetHeight(imageBuffer);
        YUVConfig conf = {0};
        conf.width = width;
        conf.height = height;
        conf.pts = pts.value;
        conf.duration = duration.value;
          [_encoder encodeWithData:imageBuffer andConfig:conf andReslutBlock:^(NSData *H264buf) {
              NSLog(@"%@",H264buf);
          }];
        
    }
    
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
  
}


@end
