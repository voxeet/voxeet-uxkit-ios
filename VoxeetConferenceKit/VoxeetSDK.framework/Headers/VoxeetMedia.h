//
//  VoxeetMedia.h
//  VoxeetMedia
//
//  Created by Thomas Gourgues on 21/08/12.
//  Copyright (c) 2012 Thomas Gourgues. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "VoxeetMediaDelegate.h"
#import "AudioCoreCodec.h"
#import "NetworkReporting.h"
#import "AudioSettings.h"
#import "VideoRenderer.h"
#import "MediaStream.h"

#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreBluetooth/CBService.h>

struct ICoreMedia;
typedef struct ICoreMedia ICoreMedia;

typedef enum{
    DeviceiPhone    = 0,
    DeviceSpeaker   = 1,
    DeviceBluetooth = 2,
    DeviceHeadset   = 3,
    DeviceNone      = 4
}AudioDevice;

typedef enum{
    LowProfile  = 0,
    HighProfile = 1
}AudioProfile;

typedef enum{
    kNoQos        = 0,
    kQosConnected = 1,
    kQosLost      = 2
}QosStatus;


@interface VoxeetMedia : NSObject {
    //ICoreMedia*  m_coreMedia;
    AudioProfile m_profile;
    CBCentralManager *m_manager;
}

//@property (readwrite, nonatomic) CBCentralManager *manager;
@property (nonatomic, assign) id <VoxeetMediaDelegate> delegate;
- (id)initWithLocalPeer:(NSString *)localPeerId audioSettings:(AudioSettings *)settings video:(BOOL)video microphone: (BOOL)microphone;
- (void)attachMediaStream:(id<VideoRenderer>)renderer withStream: (MediaStream*) stream;
- (void)unattachMediaStream:(id<VideoRenderer>)renderer withStream: (MediaStream*) stream;
- (BOOL)needSwitchToPstn;
- (BOOL)createConnectionWithPeer:(NSString *)peerId isMaster:(BOOL)isMaster;
- (BOOL)closeConnectionWithPeer:(NSString *)peerId;
- (BOOL)createAnswerForPeer:(NSString *)peerId;
- (BOOL)setDescriptionForPeer:(NSString *)peerId withSsrc:(long)ssrc type:(NSString *)type andSdp:(NSString *)sdp;
- (BOOL)setCandidateForPeer:(NSString *)peerId withsdpMid:(NSString *)sdpMid sdpIndex:(NSInteger)sdpMLineIndex andSdp:(NSString *)sdp;
- (BOOL)setPositionForPeer:(NSString *)peerId withAngle:(double)angle andPosition:(double)position;
- (BOOL)setPositionForPeer:(NSString *)peerId withAngle:(double)angle position:(double)position andGain:(float)gain;
- (BOOL)setGain:(float)gain forPeer:(NSString *)peerId;
- (void)setMute:(BOOL)mute;
- (void)setAudioOptions:(BOOL)ns agc:(BOOL)agc ec:(BOOL)ec typingDetection:(BOOL)typingDetection;
- (NSInteger)getLocalVuMeter;
- (NSInteger)getVuMeterForPeer:(NSString *)peerId;
- (void)setLoudSpeakerStatus:(BOOL)isEnable;
- (BOOL)isLoudSpeakerActive;
- (void)setHardwareAec:(BOOL)isHardwareAEC;
- (BOOL)isHardwareAec;
- (void)stop;
- (void)dealloc;
- (void)flipCamera;
- (void)startVideo;
- (void)stopVideo;

@end
