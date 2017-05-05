//
//  WrappedConnectionObserver.h
//  VoxeetMedia
//
//  Created by Gilles Bordas on 29/01/2014.
//  Copyright (c) 2014 Voxeet. All rights reserved.
//

#import "VoxeetMediaDelegate.h"
#include "connection_observer.h"
#include "connections.h"

namespace voxeet {
    class WrappedConnectionObserver : public PeerConnectionObserver , public TraceCallback , public VoiceEngineObserver {
    public:
        static WrappedConnectionObserver* Create(std::string peer, Connections* connections, id<VoxeetMediaDelegate> delegate)
        {
            RefCountedObject<WrappedConnectionObserver>* observer = new RefCountedObject<WrappedConnectionObserver>(peer, connections, delegate);
            
            observer->AddRef();
            
            return observer;
        };
        
        explicit WrappedConnectionObserver(std::string peer, Connections* connections, id<VoxeetMediaDelegate> delegate);
        
        virtual void OnError();
        virtual void OnSignalingChange(PeerConnectionInterface::SignalingState new_state);
        virtual void OnStateChange(StateType state_changed);
        virtual void OnAddStream(MediaStreamInterface* stream);
        virtual void OnRemoveStream(MediaStreamInterface* stream);
        virtual void OnDataChannel(DataChannelInterface* data_channel);
        virtual void OnRenegotiationNeeded();
        virtual void OnIceConnectionChange(PeerConnectionInterface::IceConnectionState new_state);
        virtual void OnIceGatheringChange(PeerConnectionInterface::IceGatheringState new_state);
        virtual void OnIceCandidate(const IceCandidateInterface* candidate);
  
        virtual void Print(TraceLevel level, const char* message, int length);

        virtual void CallbackOnError(int channel, int errCode);
    protected:
        virtual ~WrappedConnectionObserver();
        
    private:
        id<VoxeetMediaDelegate> _delegate;
        std::string _peer;
        Connections *_connections;
        //RTCPeerConnection *_peerConnection;
    };
}