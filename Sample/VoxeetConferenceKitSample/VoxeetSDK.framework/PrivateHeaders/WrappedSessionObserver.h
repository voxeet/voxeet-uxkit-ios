//
//  WrappedSessionObserver.h
//  VoxeetMedia
//
//  Created by Gilles Bordas on 29/01/2014.
//  Copyright (c) 2014 Voxeet. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "webrtc/api/peerconnectioninterface.h"
#import "VoxeetMediaDelegate.h"

#include "connection_owner.h"

namespace voxeet {
    class WrappedSessionObserver : public CreateSessionDescriptionObserver {
    public:
        static WrappedSessionObserver* Create(std::string peer, ConnectionOwner* owner, id<VoxeetMediaDelegate> delegate) {
            return new RefCountedObject<WrappedSessionObserver>(peer, owner, delegate);
        }
        
        WrappedSessionObserver(std::string peer, ConnectionOwner* owner, id<VoxeetMediaDelegate> delegate);
        
        virtual void SetRemoteDescription(SessionDescriptionInterface* desc);
        
        virtual void OnSuccess(SessionDescriptionInterface* desc);
        virtual void OnFailure(const std::string& error);
        
    protected:
        virtual ~WrappedSessionObserver();
        
    private:
        std::string _peer;
        ConnectionOwner* _owner;
        id<VoxeetMediaDelegate> _delegate;
    };
}