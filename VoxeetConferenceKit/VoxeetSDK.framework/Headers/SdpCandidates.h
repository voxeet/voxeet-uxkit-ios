//
//  SdpCandidates.h
//  VoxeetMedia
//
//  Created by Gilles Bordas on 10/01/2014.
//  Copyright (c) 2014 Voxeet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SdpCandidate.h"

@interface SdpCandidates : NSObject



- (void)addCandidate:(SdpCandidate *)candidate forPeer:(NSString *)peerId;
- (NSArray *)candidatesForPeer:(NSString *)peerId;
- (void)clearSdpCandidatesForPeer:(NSString *)peerId;
@end
