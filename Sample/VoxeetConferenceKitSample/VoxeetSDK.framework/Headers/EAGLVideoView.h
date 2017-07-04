/*
 *  Copyright 2015 The WebRTC project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "VideoRenderer.h"

@class VideoRenderer;

@protocol VideoRendererDelegate

- (void)videoView:(VideoRenderer *)videoView didChangeVideoSize:(CGSize)size;

@end

/**
 * RTCEAGLVideoView is an RTCVideoRenderer which renders video frames in its
 * bounds using OpenGLES 2.0.
 */
@interface VideoRenderer : UIView <VideoRenderer>

@property(nonatomic, weak) id<VideoRendererDelegate> delegate;
@property(nonatomic, assign) BOOL contentFill;

@end

