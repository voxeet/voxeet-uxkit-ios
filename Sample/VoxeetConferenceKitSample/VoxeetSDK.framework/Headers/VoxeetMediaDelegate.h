//
//  VoxeetMediaDelegate.h
//  VoxeetMedia
//
//  Created by Thomas Gourgues on 13/12/12.
//  Copyright (c) 2012 Voxeet. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MediaStream;

@protocol VoxeetMediaDelegate <NSObject>

- (void)audioRouteChanged:(NSNumber *)route;

// New audio core delegate

- (void)sessionCreatedForPeer:(NSString *)peerId withType:(NSString *)type andSdp:(NSString *)sdp;
- (void)iceCandidateDiscoveredForPeer:(NSString *)peerId withSdpMid:(NSString *)sdpMid sdpMLineIndex:(NSInteger)sdpMLineIndex andSdp:(NSString *)sdp;
- (void)iceGatheringCompletedForPeer:(NSString *)peerId;
- (void)printTraceWithLevel:(int)level withMessage:(const char*)message ofLength:(int)length;
- (void)callBackOnChannel:(int)channel withErrorCode:(int)errCode;
- (void)streamAddedForPeer:(NSString*)peerId withStream:(MediaStream*)mediaStream;
- (void)streamUpdatedForPeer:(NSString*)peerId withStream:(MediaStream*)mediaStream;
- (void)streamRemovedForPeer:(NSString*)peerId withStream:(MediaStream*)mediaStream;
- (void)screenStreamAddedForPeer:(NSString*)peerId withStream:(MediaStream*)mediaStream;
- (void)screenStreamRemovedForPeer:(NSString*)peerId withStream:(MediaStream*)mediaStream;

@end
