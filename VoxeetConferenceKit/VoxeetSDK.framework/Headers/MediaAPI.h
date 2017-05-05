//
//  MediaAPI.h
//  VoxeetMedia
//
//  Created by Gilles Bordas on 09/01/2014.
//  Copyright (c) 2014 Voxeet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VoxeetMedia.h"
#import "AudioSettings.h"
#import "SdpMessage.h"
#import "SdpCandidates.h"
#import "SdpDescription.h"
#import "SenderNetworkStatistics.h"
#import "ReceiverNetworkStatistics.h"
#import "NetworkCodec.h"
#import "VideoRenderer.h"
#import "MediaStream.h"

@protocol MediaAPIDelegate <NSObject>
  - (void)streamAddedForPeer:(NSString *)peerId withStream:(MediaStream *)mediaStream;
  - (void)streamRemovedForPeer:(NSString *)peerId withStream:(MediaStream *)mediaStream;
  - (void)streamUpdatedForPeer:(NSString *) peerId withStream:(MediaStream *)mediaStream;
  - (void)screenShareStreamAddedForPeer:(NSString *)peerId withStream:(MediaStream *)mediaStream;
  - (void)screenShareStreamRemovedForPeer:(NSString *)peerId withStream:(MediaStream *)mediaStream;
@end

@interface MediaAPI : NSObject <VoxeetMediaDelegate>

@property (nonatomic, assign) id<MediaAPIDelegate> delegate;
@property (strong, nonatomic) NSMutableDictionary *pendingOperations;
@property (strong, nonatomic) SdpCandidates *peerCandidates;
@property (strong, nonatomic) VoxeetMedia *wrapper;
@property (strong, nonatomic) AudioSettings *audioSettings;
@property (copy, nonatomic) void(^audioRouteChangedBlock)(NSNumber *);

- (id)initWithLocalUser:(NSString *)localUserId settings:(AudioSettings *)audioSettings video:(BOOL)video microphone:(BOOL)microphone andCompletionBlock:(void(^)(void))completionBlock;
- (void)stop;
- (void)setHardwareAEC:(BOOL)isHardwareAEC;
- (BOOL)isHardwareAEC;
- (void)setLoudSpeakerStatus:(BOOL)isEnable;
- (BOOL)isLoudSpeakerActive;
- (BOOL)needSwitchToPstn;
- (SdpMessage *)createOfferForPeer:(NSString *)peerId isMaster:(BOOL)isMaster;
- (SdpMessage *)createAnswerForPeer:(NSString *)peerId withSSRC:(UInt32)ssrc offer:(SdpDescription *)offer andCandidates:(NSArray *)candidates isMaster:(BOOL)isMaster;
- (void)addPeerFromAnswer:(NSString *)peerId withSSRC:(long)ssrc answer:(SdpDescription *)answer candidates:(NSArray *)candidates;
- (void)removePeer:(NSString *)peerId;
- (void)changePeerPosition:(NSString *)peerId withAngle:(double)angle andDistance:(double)distance;
- (void)changePeerPosition:(NSString *)peerId withAngle:(double)angle distance:(double)distance andGain:(float)gain;
- (void)changeGain:(float)gain forPeer:(NSString *)peerId;
- (void)attachMediaStream:(id<VideoRenderer>)renderer withStream:(MediaStream *)stream;
- (void)unattachMediaStream:(id<VideoRenderer>)renderer withStream:(MediaStream *)stream;
- (void)muteRecording;
- (void)unmuteRecording;
- (double)getLocalVuMeterLevel;
- (double)getPeerVuMeterLevel:(NSString *)peerId;
- (void)flipCamera;
- (void)startVideo;
- (void)stopVideo;

@end
