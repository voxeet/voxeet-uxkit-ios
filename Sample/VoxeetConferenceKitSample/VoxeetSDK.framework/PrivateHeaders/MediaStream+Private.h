//
//  MediaStream+Private.h
//  VoxeetSDK
//
//  Created by Thomas Gourgues on 13/07/2016.
//  Copyright © 2016 Voxeet. All rights reserved.
//

#ifndef MediaStream_Private_h
#define MediaStream_Private_h

#import "MediaStream.h"

#include "webrtc/api/mediastreaminterface.h"

@interface  MediaStream ()
/**
 * MediaStreamInterface representation of this RTCMediaStream object. This is
 * needed to pass to the underlying C++ APIs.
 */
@property(nonatomic) webrtc::MediaStreamInterface* nativeMediaStream;

/** Initialize an RTCMediaStream from a native MediaStreamInterface. */
- (instancetype)initWithNativeMediaStream: (rtc::scoped_refptr<webrtc::MediaStreamInterface>)nativeMediaStream;

@end

#endif /* MediaStream_Private_h */
