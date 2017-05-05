//
//  PendingPeerOperation.h
//  VoxeetMedia
//
//  Created by Gilles Bordas on 14/01/2014.
//  Copyright (c) 2014 Voxeet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ITBlockingQueue.h"

typedef enum
{
    PendingPeerOperationTypeOffer,
    PendingPeerOperationTypeAnswer,
    PendingPeerOperationTypeCandidates,
    PendingPeerOperationTypeNone
}PendingPeerOperationType;

@interface PendingPeerOperation : NSObject

@property (assign, nonatomic) PendingPeerOperationType type;
@property (strong, nonatomic) NSString *peerId;
@property (strong, nonatomic) ITBlockingQueue *blockingQueue;

- (id)initWithType:(PendingPeerOperationType)type andPeerId:(NSString *)peerId;
- (id)waitUntilTimeout:(NSTimeInterval)timeout;
- (BOOL)tryUnlockWithType:(PendingPeerOperationType)type peerId:(NSString *)peerId andValue:(id)value;
- (NSString *)identifier;

+ (NSString *)identifierForPeerId:(NSString *)peerId andType:(PendingPeerOperationType)type;

@end
