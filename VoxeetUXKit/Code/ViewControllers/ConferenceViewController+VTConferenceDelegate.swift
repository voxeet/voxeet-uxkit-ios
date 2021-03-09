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
    
    func permissionsUpdated(permissions: [Int]) {
        let conferenceConfig = VoxeetUXKit.shared.conferenceController?.configuration
        let actionBarConfig = conferenceConfig?.actionBar
        
        // Check conference mode.
        let mode = VoxeetSDK.shared.conference.mode
        guard mode == .standard else { return }
        
        // Get permissions.
        var conferencePermissions = [VTConferencePermission]()
        for permission in permissions {
            if let conferencePermission = VTConferencePermission(rawValue: permission) {
                conferencePermissions.append(conferencePermission)
            }
        }
        
        // Video permission.
        if actionBarConfig?.displayCamera == true {
            if !conferencePermissions.contains(.sendVideo) {
                actionBarVC.cameraButton(state: .off)
                actionBarVC.cameraButton.isHidden = true
            } else {
                actionBarVC.cameraButton.isHidden = false
            }
        }
        // Screen share permission.
        if actionBarConfig?.displayScreenShare == true {
            if !conferencePermissions.contains(.shareScreen) {
                if presenterID == nil {
                    actionBarVC.screenShareButton(state: .off)
                }
                actionBarVC.screenShareButton.isHidden = true
            } else {
                actionBarVC.screenShareButton.isHidden = false
            }
        }
        // Audio permission.
        if actionBarConfig?.displayMute == true {
            if !conferencePermissions.contains(.sendAudio) {
                actionBarVC.muteButton(state: .on)
                actionBarVC.muteButton.isHidden = true
                
                // Monkey patch: need to restart the audio after loosing the permission.
                audioPermissionInitiate = true
            } else {
                actionBarVC.muteButton.isHidden = false
            }
        }
        
        // Action bar animation.
        UIView.animate(withDuration: 0.25) {
            self.actionBarVC.view.layoutIfNeeded()
        }
    }
    
    func participantAdded(participant: VTParticipant) {
        let conferenceConfig = VoxeetUXKit.shared.conferenceController?.configuration
        let participantsConfig = conferenceConfig?.participants
        let isListener = participant.type == .listener && participant.status == .connected
        let isLeftParticipantsDisplayed = participantsConfig?.displayLeftParticipants ?? false
        let isSessionParticipant = participant.id == VoxeetSDK.shared.session.participant?.id
        
        // Append invited, listeners or left participant from collection view.
        if !isSessionParticipant {
            if participant.status == .reserved || isListener || isLeftParticipantsDisplayed {
                participantsVC.append(participant: participant)
            }
        }
    }
    
    func participantUpdated(participant: VTParticipant) {
        let sessionService = VoxeetSDK.shared.session
        let conferenceConfig = VoxeetUXKit.shared.conferenceController?.configuration
        let participantsConfig = conferenceConfig?.participants
        let isLeftParticipantsDisplayed = participantsConfig?.displayLeftParticipants ?? false
        let isSessionParticipant = participant.id == VoxeetSDK.shared.session.participant?.id
        
        // Append / Update / Remove participant from collection view.
        if !isSessionParticipant {
            if participant.status == .connected || isLeftParticipantsDisplayed {
                participantsVC.append(participant: participant) /* Append or update participant */
            } else {
                participantsVC.remove(participant: participant)
            }
        }
        
        // Show / Hide own video renderer.
        let videoTracks = sessionService.participant?.streams.first(where: { $0.type == .Camera })?.videoTracks
        hideOwnVideoRenderer((videoTracks?.isEmpty ?? true) || activeParticipants().isEmpty)
        
        // Update conference state label and active speaker.
        if activeParticipants().isEmpty {
            // Update conference state label.
            if conferenceStateLabel.text == nil {
                conferenceStateLabel.text = VTUXLocalized.string("VTUX_CONFERENCE_STATE_CALLING")
            }
            conferenceStateLabel.isHidden = false
            
            // End active speaker timer.
            activeSpeaker.end()
        } else {
            // Hide conference state when a participant joins the conference.
            conferenceStateLabel.text = nil
            conferenceStateLabel.isHidden = true
            
            // Reset active speaker.
            activeSpeaker.begin()
            activeSpeaker.refresh()
            
            // Stop outgoing sound when a participant enters in conference.
            if participant.id != sessionService.participant?.id {
                outgoingSound?.stop()
            }
        }
    }
    
    func streamAdded(participant: VTParticipant, stream: MediaStream) {
        // Monkey patch: wait WebRTC media to be started (avoids sound button to blink).
        if conferenceStartTimer == nil {
            conferenceStartTimer = Timer.scheduledTimer(timeInterval: 1.5, target: self, selector: #selector(conferenceStarted), userInfo: nil, repeats: false)
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
            // Attach stream to the own video renderer.
            if !stream.videoTracks.isEmpty {
                ownVideoRenderer.attach(participant: participant, stream: stream)
                
                // Enable camera button (in case of `join` method with `video` true).
                actionBarVC.cameraButton(state: .on)
            }
            
            // Show / Hide own video renderer.
            hideOwnVideoRenderer(stream.videoTracks.isEmpty || activeParticipants().isEmpty)
        } else {
            // Reload participant's cell from collection view.
            participantsVC.reloadCell(participant: participant)
        }
        
        // Refresh active speaker.
        activeSpeaker.refresh()
    }
    
    private func cameraStreamRemoved(participant: VTParticipant, stream: MediaStream) {
        let sessionService = VoxeetSDK.shared.session
        
        if participant.id != sessionService.participant?.id {
            let conferenceConfig = VoxeetUXKit.shared.conferenceController?.configuration
            let participantsConfig = conferenceConfig?.participants
            if participantsConfig?.displayLeftParticipants ?? false {
                // Reload participant's cell from collection view.
                participantsVC.reloadCell(participant: participant)
            }
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
            // Stop active speaker and lock the current participant.
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
    
    private func hideOwnVideoRenderer(_ isHidden: Bool) {
        UIView.animate(withDuration: 0.125, animations: {
            self.ownVideoRenderer.alpha = !isHidden && !self.isMinimized ? 1 : 0
            self.flipImage.alpha = self.ownVideoRenderer.alpha
        })
    }
}
