//
//  VTUXActiveSpeakerTimer.swift
//  VoxeetUXKit
//
//  Created by Corentin Larroque on 14/06/2019.
//  Copyright © 2019 Voxeet. All rights reserved.
//

import VoxeetSDK

@objc public protocol VTUXActiveSpeakerTimerDelegate {
    func activeSpeakerUpdated(user: VTUser?)
}

@objc public class VTUXActiveSpeakerTimer: NSObject {
    @objc public weak var delegate: VTUXActiveSpeakerTimerDelegate?
    
    private var speaker: VTUser?
    private var selectedUser: VTUser?
    
    private var activeSpeakerTimer: Timer?
    private let activeSpeakerDelay: TimeInterval = 1
    
    @objc public func begin() {
        guard selectedUser == nil else { return }
        
        activeSpeakerTimer?.invalidate()
        activeSpeakerTimer = Timer.scheduledTimer(timeInterval: activeSpeakerDelay,
                                                  target: self,
                                                  selector: #selector(activeSpeakerRefresh),
                                                  userInfo: nil,
                                                  repeats: true)
        activeSpeakerTimer?.fire()
    }
    
    @objc public func refresh() {
        // Check if there is a selected user.
        if let user = selectedUser, user.hasStream {
            delegate?.activeSpeakerUpdated(user: user)
            return
        }
        
        // Refresh active speaker.
        speaker = nil
        activeSpeakerRefresh()
        
        // If the speaker is still nil after refreshing, call the delegate to update UI.
        if speaker == nil {
            delegate?.activeSpeakerUpdated(user: nil)
        }
    }
    
    @objc public func end() {
        speaker = nil
        selectedUser = nil
        activeSpeakerTimer?.invalidate()
        
        // Call the delegate to update UI.
        delegate?.activeSpeakerUpdated(user: nil)
    }
    
    @objc public func lock(user: VTUser?) {
        speaker = nil
        selectedUser = user
        
        if let user = user {
            activeSpeakerTimer?.invalidate()
            delegate?.activeSpeakerUpdated(user: user)
        } else {
            begin()
        }
    }
    
    @objc private func activeSpeakerRefresh() {
        var loudestSpeaker: VTUser?
        var loudestVoiceLevel: Double = 0
        
        // Get the loudest speaker.
        let users = VoxeetSDK.shared.conference.users.filter({ $0.hasStream })
        if !users.isEmpty {
            for user in users {
                if let userID = user.id {
                    let voiceLevel = VoxeetSDK.shared.conference.voiceLevel(userID: userID)
                    if voiceLevel >= loudestVoiceLevel {
                        loudestSpeaker = user
                        loudestVoiceLevel = voiceLevel
                    }
                }
            }
        }
        
        // Optimize active speaker updates.
        if let loudestSpeaker = loudestSpeaker {
            if (loudestVoiceLevel >= 0.01 || speaker == nil) && loudestSpeaker.id != speaker?.id {
                speaker = loudestSpeaker
                delegate?.activeSpeakerUpdated(user: speaker)
            }
        }
    }
}
