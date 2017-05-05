//
//  SdpMessage.h
//  VoxeetMedia
//
//  Created by Gilles Bordas on 10/01/2014.
//  Copyright (c) 2014 Voxeet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SdpDescription.h"

@interface SdpMessage : NSObject

@property (strong, nonatomic) SdpDescription *sdpDescription;
@property (strong, nonatomic) NSArray *candidates;

- (id)initWithDescription:(SdpDescription *)sdpDescription andCandidates:(NSArray *)candidates;

@end
