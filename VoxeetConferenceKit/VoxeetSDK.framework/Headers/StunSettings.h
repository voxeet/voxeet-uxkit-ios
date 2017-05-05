//
//  StunSettings.h
//  VoxeetMedia
//
//  Created by Gilles Bordas on 10/01/2014.
//  Copyright (c) 2014 Voxeet. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StunSettings : NSObject

@property (strong, nonatomic) NSString *stunHost;
@property (assign, nonatomic) NSInteger stunPort;

- (id)initWithHost:(NSString *)host andPort:(NSInteger)port;

@end
