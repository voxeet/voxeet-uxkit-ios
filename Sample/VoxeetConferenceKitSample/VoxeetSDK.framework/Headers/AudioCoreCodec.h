//
//  AudioCodec.h
//  VoxeetMedia
//
//  Created by Gilles Bordas on 14/01/2014.
//  Copyright (c) 2014 Voxeet. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AudioCoreCodec : NSObject

@property (assign, nonatomic) NSInteger payloadType;
@property (strong, nonatomic) NSString *payloadName;
@property (assign, nonatomic) NSInteger payloadFrequency;
@property (assign, nonatomic) NSInteger packetSize;
@property (assign, nonatomic) NSInteger channelsCount;
@property (assign, nonatomic) NSInteger rate;

@end
