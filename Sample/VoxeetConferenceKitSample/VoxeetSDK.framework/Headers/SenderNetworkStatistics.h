//
//  SenderNetworkStatistics.h
//  VoxeetMedia
//
//  Created by Gilles Bordas on 10/01/2014.
//  Copyright (c) 2014 Voxeet. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SenderNetworkStatistics : NSObject

@property (assign, nonatomic) NSInteger rtcpBytesSent;
@property (assign, nonatomic) NSInteger rtcpPacketsSent;

//+ (SenderNetworkStatistics *)senderStatisticsFromNetworkReporting:(id/*SenderNetworkReport **/)reporting;

@end
