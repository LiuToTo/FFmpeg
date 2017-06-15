//
//  H264EncodeManager.h
//  FFmpegTest
//
//  Created by vip-刘旭 on 2017/6/15.
//  Copyright © 2017年 vip-刘旭. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef void(^encodeBlock)(NSData* H264buf);
typedef struct {
    int width;
    int height;
    int64_t pts;// 视频帧出现时间
    int64_t duration;
}   YUVConfig;
@interface H264EncodeManager : NSObject
/**
 *  H264编码
 *
 *  @param data   未编码数据
 *  @param width  视频宽
 *  @param height 视频高
 *  @param reslut H264数据
 */
- (void)encodeWithData:(const void*)data andConfig:(YUVConfig)config andReslutBlock:(encodeBlock)reslut;
@end

