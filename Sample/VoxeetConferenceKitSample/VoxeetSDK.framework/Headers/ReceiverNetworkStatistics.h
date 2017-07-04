//
//  ReceiverNetworkStatistics.h
//  VoxeetMedia
//
//  Created by Gilles Bordas on 10/01/2014.
//  Copyright (c) 2014 Voxeet. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ReceiverNetworkStatistics : NSObject

@property (assign, nonatomic) NSInteger netEqCurrentBufferSize;
@property (assign, nonatomic) NSInteger netEqCurrentDiscardRate;
@property (assign, nonatomic) NSInteger netEqCurrentExpandRate;
@property (assign, nonatomic) NSInteger netEqCurrentPacketLossRate;
@property (assign, nonatomic) NSInteger netEqMinWaitingTime;
@property (assign, nonatomic) NSInteger netEqMeanWaitingTime;
@property (assign, nonatomic) NSInteger netEqMedianWaitingTime;
@property (assign, nonatomic) NSInteger netEqMaxWaitingTime;
@property (assign, nonatomic) NSUInteger rtpAverageJitter;
@property (assign, nonatomic) NSUInteger rtpMaxJitter;
@property (assign, nonatomic) NSUInteger rtpDiscardedPackets;
@property (assign, nonatomic) NSInteger rtcpBytesReceived;
@property (assign, nonatomic) NSInteger rtcpPacketsReceived;
@property (assign, nonatomic) NSUInteger rtcpJitterSamples;
@property (assign, nonatomic) NSInteger rtcpRoundTripTime;

//+ (ReceiverNetworkStatistics *)receiverStatisticsFromNetworkReporting:(id/*ReceiverNetworkReport **/)reporting;

/*

#region << Inner classes >>

public class RtcpStatisticsBlock
{
    public long SenderSSRC
    {
        get;
        set;
    }
    
    public long SourceSSRC
    {
        get;
        set;
    }
    
    public short FractionLost
    {
        get;
        set;
    }
    
    public long CumulativePacketsLost
    {
        get;
        set;
    }
    
    public long InterArrivalJitter
    {
        get;
        set;
    }
    
    public long LastReportTimestamp
    {
        get;
        set;
    }
    
    public long DelaySinceLastReport
    {
        get;
        set;
    }
    
    internal static RtcpStatisticsBlock FromReportBlock(RtcpReportBlock block)
    {
        return new RtcpStatisticsBlock
        {
            SenderSSRC = block.GetSenderSSRC(),
            SourceSSRC = block.GetSourceSSRC(),
            CumulativePacketsLost = block.GetCumulativeNumPacketsLost(),
            DelaySinceLastReport = block.GetDelaySinceLastSR(),
            FractionLost = block.GetFractionLost(),
            InterArrivalJitter = block.GetInterarrivalJitter(),
            LastReportTimestamp = block.GetLastSRTimestamp()
        };
    }
}

#endregion
*/

@end
