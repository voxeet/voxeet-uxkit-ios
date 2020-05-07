//
//  ConferenceViewController+VTConferenceDelegate.swift
//  VoxeetUXKit
//
//  Created by Corentin Larroque on 16/02/2017.
//  Copyright © 2017 Voxeet. All rights reserved.
//

import VoxeetSDK

extension ConferenceViewController: VTConferenceDelegate {
    func statusUpdated(status: VTConferenceStatus) {}
    
    func participantAdded(participant: VTParticipant) {
        let conferenceConfig = VoxeetUXKit.shared.conferenceController?.configuration
        let participantsConfig = conferenceConfig?.participants
        let displayLeftParticipants = participantsConfig?.displayLeftParticipants ?? false
        
        let isSessionParticipant = participant.id == VoxeetSDK.shared.session.participant?.id
        
        // Show invited and left participants.
        if (participant.status == .reserved || displayLeftParticipants) && !isSessionParticipant {
            participantsVC.append(participant: participant)
        }
    }
    
    func participantUpdated(participant: VTParticipant) {}
    
    func streamAdded(participant: VTParticipant, stream: MediaStream) {
        // Monkey patch: Wait WebRTC media to be started (avoids sound button to blink).
        if conferenceStartTimer == nil {
            conferenceStartTimer = Timer.scheduledTimer(timeInterval: 1.5, target: self, selector: #selector(conferenceStarted), userInfo: nil, repeats: false)
        }
        
        if participant.id != VoxeetSDK.shared.session.participant?.id {
            // Begin active speaker timer.
            activeSpeaker.begin()
            
            // Hide conference state when a participant joins the conference.
            conferenceStateLabel.isHidden = true
            conferenceStateLabel.text = nil
            
            // Stop outgoing sound when a participant enters in conference.
            outgoingSound?.stop()
            
            // Update participant's audio position to listen each people clearly in a 3D environment.
            updateParticipantPosition()
        }
        
        streamUpdated(participant: participant, stream: stream)
    }
    
    func streamUpdated(participant: VTParticipant, stream: MediaStream) {
        switch stream.type {
        case .Camera:
            cameraStreamUpdated(participant: participant, stream: stream)
        case .ScreenShare:
            screenShareStreamUpdated(participant: participant, stream: stream)
        default: break
        }
    }
    
    func streamRemoved(participant: VTParticipant, stream: MediaStream) {
        switch stream.type {
        case .Camera:
            cameraStreamRemoved(participant: participant, stream: stream)
        case .ScreenShare:
            screenShareStreamRemoved(participant: participant, stream: stream)
        default: break
        }
    }
    
    private func cameraStreamUpdated(participant: VTParticipant, stream: MediaStream) {
        let sessionService = VoxeetSDK.shared.session
        
        if participant.id == sessionService.participant?.id {
            // Attach own stream to the own video renderer.
            if !stream.videoTracks.isEmpty {
                ownVideoRenderer.attach(participant: participant, stream: stream)
                // Enable camera button (in case of `join` method with `video` true).
                actionBarVC.cameraButton(state: .on)
            }
        } else {
            // Append / Refresh participants' collection view.
            participantsVC.append(participant: participant)
            
            // Refresh active speaker.
            activeSpeaker.refresh()
        }
        
        // Show / Hide own video renderer or refresh active speaker.
        if let participant = sessionService.participant {
            if !(participant.streams.first(where: { $0.type == .Camera })?.videoTracks.isEmpty ?? true) {
                if !activeParticipants().isEmpty {
                    isOwnVideoRendererHidden(false)
                } else {
                    activeSpeaker.refresh()
                }
            } else {
                if !activeParticipants().isEmpty {
                    isOwnVideoRendererHidden(true)
                } else {
                    activeSpeaker.refresh()
                }
            }
        }
    }
    
    private func cameraStreamRemoved(participant: VTParticipant, stream: MediaStream) {
        if participant.id != VoxeetSDK.shared.session.participant?.id {
            // Reload collection view to update/remove inactive participants.
            let conferenceConfig = VoxeetUXKit.shared.conferenceController?.configuration
            let participantsConfig = conferenceConfig?.participants
            if participantsConfig?.displayLeftParticipants ?? false {
                participantsVC.update(participant: participant)
            } else {
                participantsVC.remove(participant: participant)
            }
            
            if activeParticipants().isEmpty {
                // Show own renderer.
                isOwnVideoRendererHidden(true)
                
                // Update conference state label.
                if conferenceStateLabel.text == nil {
                    conferenceStateLabel.text = VTUXLocalized.string("VTUX_CONFERENCE_STATE_CALLING")
                }
                conferenceStateLabel.isHidden = false
                
                // End active speaker timer.
                activeSpeaker.end()
            } else {
                activeSpeaker.refresh()
            }
            
            // Update participants's audio position to listen each people clearly in a 3D environment.
            updateParticipantPosition()
        }
    }
    
    private func screenShareStreamUpdated(participant: VTParticipant, stream: MediaStream) {
        if participant.id == VoxeetSDK.shared.session.participant?.id {
            // Enable screen share button when broadcast mode is enabled.
            let broadcast = VoxeetSDK.shared.appGroup != nil
            if broadcast {
                actionBarVC.screenShareButton(state: .on)
            }
        } else if !stream.videoTracks.isEmpty {
            // Stop active speaker and lock current participant.
            startPresentation(participant: participant)
            
            // Attach screen share stream.
            speakerVideoContentFill = speakerVideoVC.videoRenderer.contentFill
            speakerVideoVC.unattach()
            speakerVideoVC.attach(participant: participant, stream: stream)
            speakerVideoVC.contentFill(false, animated: false)
            speakerVideoVC.view.isHidden = false
        }
    }
    
    private func screenShareStreamRemoved(participant: VTParticipant, stream: MediaStream) {
        if participant.id == VoxeetSDK.shared.session.participant?.id {
            // Disable screen share button when broadcast mode is enabled.
            let broadcast = VoxeetSDK.shared.appGroup != nil
            if broadcast {
                actionBarVC.screenShareButton(state: .off)
            }
        } else {
            // Unattach screen share stream.
            speakerVideoVC.unattach()
            speakerVideoVC.contentFill(speakerVideoContentFill, animated: false)
            speakerVideoVC.view.isHidden = true
            
            // Reset active speaker and unlock previous participant.
            stopPresentation()
        }
    }
    
    private func isOwnVideoRendererHidden(_ isHidden: Bool) {
        UIView.animate(withDuration: 0.125, animations: {
            self.ownVideoRenderer.alpha = !isHidden && !self.isMinimized ? 1 : 0
            self.flipImage.alpha = self.ownVideoRenderer.alpha
        })
    }
    
    private func updateParticipantPosition() {
        let participants = activeParticipants()
        let sliceAngle = Double.pi / Double(participants.count)
        
        for (index, participant) in participants.enumerated() {
            let angle = ((Double.pi / 2) - (Double.pi - (sliceAngle * Double(index) + sliceAngle / 2))) / (Double.pi / 2)
            VoxeetSDK.shared.conference.position(participant: participant, angle: angle, distance: 0.2)
        }
    }
}
