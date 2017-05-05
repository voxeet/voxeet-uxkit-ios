//
//  SdpCandidate.h
//  VoxeetMedia
//
//  Created by Gilles Bordas on 10/01/2014.
//  Copyright (c) 2014 Voxeet. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SdpCandidate : NSObject

@property (strong, nonatomic) NSString *sdpMid;
@property (assign, nonatomic) NSInteger sdpMLineIndex;
@property (strong, nonatomic) NSString *sdp;

- (id)initWithSdpMid:(NSString *)sdpMid sdpMLineIndex:(NSInteger)sdpMLineIndex andSdp:(NSString *)sdp;

@end
