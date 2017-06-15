//
//  H264EncodeManager.m
//  FFmpegTest
//
//  Created by vip-刘旭 on 2017/6/15.
//  Copyright © 2017年 vip-刘旭. All rights reserved.
//

#import "H264EncodeManager.h"
#import <libavcodec/avcodec.h>
#import <libavformat/avformat.h>
#import <libavutil/opt.h>
#import <libavutil/imgutils.h>
#import <libswscale/swscale.h>
@interface H264EncodeManager()
{
    dispatch_queue_t _encode_queue;
    dispatch_queue_t _main_queue;
}
@property (nonatomic, assign) int64_t pts;
/**
 *  编解码器环境
 */
@property (nonatomic, assign) AVCodecContext *codecContext;

/**
 *  编解码器
 */
@property (nonatomic, assign) AVCodec *H264Codec;

/**
 *  编码返回结果
 */
@property (nonatomic, strong) encodeBlock encodeReslutBlock;

@end
@implementation H264EncodeManager
- (instancetype)init {
    if (self = [super init]) {
        
        _encode_queue = dispatch_queue_create("encodeQueue", nil);
        _main_queue = dispatch_get_main_queue();
        if (![self setEncode]) {
            return nil;
        }
    }
    return self;
}

- (void)dealloc {
    
    _H264Codec = nil;
    avcodec_close(_codecContext);
    avcodec_free_context(&_codecContext);
    _codecContext = nil;
    
}

#pragma mark - Private
- (BOOL)setEncode
{
    // 初始化codec
    avcodec_register_all();
    _H264Codec = avcodec_find_encoder(AV_CODEC_ID_H264);
    if (_H264Codec == nil) {
        NSLog(@"编解码器不支持");
        return  NO;
    }
    
    //  初始化上下文
    _codecContext = avcodec_alloc_context3(_H264Codec);
    if (_codecContext == nil) {
        NSLog(@"初始化编解码环境失败");
        return NO;
    }
    _codecContext -> width = 640;
    _codecContext -> height = 480;
    _codecContext->pix_fmt = AV_PIX_FMT_YUV420P;

    /* put sample parameters */
    _codecContext->bit_rate = 400000;
    //    c->bit_rate_tolerance = 10;
    //    c->me_method = 2;
    /* resolution must be a multiple of two */
    /* frames per second */
    _codecContext->time_base= (AVRational){1,25};
    _codecContext->gop_size = 10;//25; /* emit one intra frame every ten frames */
    _codecContext->max_b_frames=1;
    _codecContext->pix_fmt = AV_PIX_FMT_YUV420P;
    _codecContext->thread_count = 1;
    
    //  打开编码器
    if(avcodec_open2(_codecContext, _H264Codec, NULL) < 0) {
        
        NSLog(@"打开编码器失败");
        return NO;
    }
    return YES;
}

#pragma mark - 编码
- (void)encodeWithData:(const void *)data andConfig:(YUVConfig)config andReslutBlock:(encodeBlock)reslut {
    dispatch_sync(_encode_queue, ^{
        
        if (reslut != nil) {
            _encodeReslutBlock = [reslut copy];
            
            AVFrame *codecFrame;
            _pts ++;
            codecFrame = av_frame_alloc();
            codecFrame->width = config.width;
            codecFrame->height = config.height;
            codecFrame->format = _codecContext->pix_fmt;
            codecFrame->pts = _pts;
            
            AVPacket packet;
            av_init_packet(&packet);
            packet.size = 0;
            packet.data = NULL;
            
            
            avpicture_fill((AVPicture*)codecFrame, data, _codecContext->pix_fmt, config.width, config.height);
            
            //  解码
            int ret = 0;
            int got_picture = 0;
            
            
            ret = avcodec_encode_video2(_codecContext, &packet, codecFrame, &got_picture);
            if (got_picture) {
                NSData *buffer = [NSData dataWithBytes:packet.data length:packet.size];
                dispatch_async(_main_queue, ^{
                    _encodeReslutBlock(buffer);
                });
            }
            
            //  释放
            av_frame_free(&codecFrame);
            av_free_packet(&packet);
        }
    });
}
@end
