/*
 *  Copyright 2015 The WebRTC project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import "VideoRendererAdapter.h"

#import "VideoRenderer.h"

#include "webrtc/api/mediastreaminterface.h"

@interface VideoRendererAdapter ()

/**
 * The Objective-C video renderer passed to this adapter during construction.
 * Calls made to the webrtc::VideoRenderInterface will be adapted and passed to
 * this video renderer.
 */
@property(nonatomic, readonly) id<VideoRenderer> videoRenderer;

/**
 * The native VideoSinkInterface surface exposed by this adapter. Calls made
 * to this interface will be adapted and passed to the RTCVideoRenderer supplied
 * during construction. This pointer is unsafe and owned by this class.
 */
@property(nonatomic)
    rtc::VideoSinkInterface<cricket::VideoFrame> *nativeVideoRenderer;

/** Initialize an RTCVideoRendererAdapter with an RTCVideoRenderer. */
- (instancetype)initWithNativeRenderer:(id<VideoRenderer>)videoRenderer;

@end
