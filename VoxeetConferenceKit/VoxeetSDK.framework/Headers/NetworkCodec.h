//
//  NetworkCodec.h
//  VoxeetMedia
//
//  Created by Gilles Bordas on 10/01/2014.
//  Copyright (c) 2014 Voxeet. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef enum {
    PayloadTypeNone
}PayloadType;

@interface NetworkCodec : NSObject

@property (assign, nonatomic) PayloadType payloadType;
@property (strong, nonatomic) NSString *payloadName;
@property (assign, nonatomic) NSInteger payloadFrequency;
@property (assign, nonatomic) NSInteger packetSize;
@property (assign, nonatomic) NSInteger numChannels;
@property (assign, nonatomic) NSInteger rate;

//- (id)initWithPayloadType:(PayloadType)type name:(NSString *)name frequency:(NSInteger)frequency packetSize:(NSInteger)packetSize numChannels:(NSInteger)numChannels andRate:(NSInteger)rate;

@end
