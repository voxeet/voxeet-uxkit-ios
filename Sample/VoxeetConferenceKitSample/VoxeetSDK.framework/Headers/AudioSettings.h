//
//  AudioSettings.h
//  Messaging
//
//  Created by Julien Besse on 06/08/12.
//  Copyright (c) 2012 Innovantic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StunSettings.h"

@protocol AudioSettingsDelegate;

@interface AudioSettings : NSObject

@property (assign, nonatomic) BOOL noiseSuppressionEnabled;
@property (assign, nonatomic) BOOL automaticGainControlEnabled;
@property (assign, nonatomic) BOOL echoControlEnabled;
@property (assign, nonatomic) BOOL typingDetectionEnabled;
@property (assign, nonatomic) NSInteger playoutDevice;
@property (assign, nonatomic) NSInteger opusComplexity;

@property (strong, readonly, nonatomic) NSString *stunHost;
@property (strong, nonatomic) StunSettings *stunSettings;
@property (weak, nonatomic) id<AudioSettingsDelegate> delegate;

- (id)initWithStunSettings:(StunSettings *)settings;

@end

@protocol AudioSettingsDelegate <NSObject>

- (void)playoutDeviceDidUpdate;
- (void)audioPropertyDidUpdate;

@end