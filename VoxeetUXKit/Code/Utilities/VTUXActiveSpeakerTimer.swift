//
//  VTUXActiveSpeakerTimer.swift
//  VoxeetUXKit
//
//  Created by Corentin Larroque on 14/06/2019.
//  Copyright © 2019 Voxeet. All rights reserved.
//

import VoxeetSDK

@objc public protocol VTUXActiveSpeakerTimerDelegate {
    func activeSpeakerUpdated(participant: VTParticipant?)
}

@objc public class VTUXActiveSpeakerTimer: NSObject {
    @objc public weak var delegate: VTUXActiveSpeakerTimerDelegate?
    
    private var speaker: VTParticipant?
    private var selectedParticipant: VTParticipant?
    
    private var activeSpeakerTimer: Timer?
    private let activeSpeakerDelay: TimeInterval = 3

    private let audioLevelTreshold: Float = 0.05
    
    @objc public func begin() {
        guard selectedParticipant == nil else { return }
        
        activeSpeakerTimer?.invalidate()
        activeSpeakerTimer = Timer.scheduledTimer(timeInterval: activeSpeakerDelay,
                                                  target: self,
                                                  selector: #selector(refreshActiveSpeaker),
                                                  userInfo: nil,
                                                  repeats: true)
        activeSpeakerTimer?.tolerance = activeSpeakerDelay / 2
        RunLoop.current.add(activeSpeakerTimer!, forMode: .common)
    }
    
    @objc public func refresh() {
        // Check if there is a selected participant.
        if let participant = selectedParticipant, !participant.streams.isEmpty {
            delegate?.activeSpeakerUpdated(participant: participant)
            return
        }
        
        // Refresh active speaker.
        speaker = nil
        refreshActiveSpeaker()
        
        // If the speaker is still nil after refreshing, call the delegate to update UI.
        if speaker == nil {
            delegate?.activeSpeakerUpdated(participant: nil)
        }
    }
    
    @objc public func end() {
        speaker = nil
        selectedParticipant = nil
        activeSpeakerTimer?.invalidate()
        
        // Call the delegate to update UI.
        delegate?.activeSpeakerUpdated(participant: nil)
    }
    
    @objc public func lock(participant: VTParticipant?) {
        speaker = nil
        selectedParticipant = participant
        
        if let participant = participant {
            activeSpeakerTimer?.invalidate()
            delegate?.activeSpeakerUpdated(participant: participant)
        } else {
            begin()
        }
    }
    
    @objc private func refreshActiveSpeaker() {
        var loudestSpeaker: VTParticipant?
        var loudestVoiceLevel: Float = 0
        
        // Get the loudest speaker.
        let participants = VoxeetSDK.shared.conference.current?.participants
            .filter({ $0.id != VoxeetSDK.shared.session.participant?.id })
            .filter({ $0.type == .user && $0.status == .connected })
        if let participants = participants, !participants.isEmpty {
            for participant in participants {
                let audioLevel = VoxeetSDK.shared.conference.audioLevel(participant: participant)
                if audioLevel >= loudestVoiceLevel {
                    loudestSpeaker = participant
                    loudestVoiceLevel = audioLevel
                }
            }
        }
        
        // Optimize active speaker updates.
        if let loudestSpeaker = loudestSpeaker {
            if (loudestVoiceLevel >= audioLevelTreshold || speaker == nil) && loudestSpeaker.id != speaker?.id {
                speaker = loudestSpeaker
                delegate?.activeSpeakerUpdated(participant: speaker)
            }
        }
    }
}
