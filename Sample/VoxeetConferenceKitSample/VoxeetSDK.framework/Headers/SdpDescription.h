//
//  SdpDescription.h
//  VoxeetMedia
//
//  Created by Gilles Bordas on 10/01/2014.
//  Copyright (c) 2014 Voxeet. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SdpDescription : NSObject

@property (strong, nonatomic) NSString *type;
@property (strong, nonatomic) NSString *sdp;
@property (assign, nonatomic) UInt32 ssrc;

- (id)initWithType:(NSString *)type sdp:(NSString *)sdp;

@end
