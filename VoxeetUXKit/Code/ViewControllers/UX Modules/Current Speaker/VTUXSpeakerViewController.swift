//
//  VTUXSpeakerViewController.swift
//  VoxeetUXKit
//
//  Created by Corentin Larroque on 13/06/2019.
//  Copyright © 2019 Voxeet. All rights reserved.
//

import VoxeetSDK
import Kingfisher

@objc public class VTUXSpeakerViewController: UIViewController {
    @IBOutlet weak private var avatar: UIRoundImageView!
    @IBOutlet weak private var name: UILabel!
    
    private var speaker: VTUser?
    
    private let voiceLevelTimeInterval: TimeInterval = 0.1
    private let voiceLevelTimerQueue = DispatchQueue(label: "com.voxeet.uxkit.voiceLevelTimer", qos: .background, attributes: .concurrent)
    private var voiceLevelTimer: Timer?
    
    private let inactiveAlpha: CGFloat = 0.6
    
    @objc public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Users list configuration.
        let speakerConfiguration = VoxeetUXKit.shared.conferenceController?.configuration.speaker
        avatar.layer.borderColor = (speakerConfiguration?.speakingUserColor ?? .clear).cgColor
        
        // Init voice level timer.
        voiceLevelTimerQueue.async { [unowned self] in
            self.voiceLevelTimer = Timer.scheduledTimer(timeInterval: self.voiceLevelTimeInterval, target: self, selector: #selector(self.refreshVoiceLevel), userInfo: nil, repeats: true)
            let currentRunLoop = RunLoop.current
            currentRunLoop.add(self.voiceLevelTimer!, forMode: .common)
            currentRunLoop.run()
        }
    }
    
    @objc override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Stop voice level timer.
        if voiceLevelTimer != nil {
            voiceLevelTimerQueue.sync { [unowned self] in
                self.voiceLevelTimer?.invalidate()
                self.voiceLevelTimer = nil
            }
        }
    }
    
    @objc public func updateSpeaker(user: VTUser) {
        speaker = user
        
        // Update avatar and name.
        let avatarURL = user.avatarURL ?? ""
        let imageURLStr = avatarURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let imageURL = URL(string: imageURLStr) {
            avatar.kf.setImage(with: imageURL)
        } else {
            avatar.image = UIImage(named: "UserPlaceholder", in: Bundle(for: type(of: self)), compatibleWith: nil)
        }
        name.text = user.name
        name.alpha = inactiveAlpha
        
        // Refresh new voice level.
        refreshVoiceLevel()
    }
    
    @objc private func refreshVoiceLevel() {
        DispatchQueue.main.async {
            if let userID = self.speaker?.id {
                let voiceLevel = VoxeetSDK.shared.conference.voiceLevel(userID: userID)
                
                if voiceLevel >= 0.05 && self.name.alpha != 1 {
                    self.avatar.layer.borderWidth = self.avatar.frame.width * (3/100) /* 3% */
                    self.name.alpha = 1
                } else if voiceLevel < 0.05 && self.name.alpha == 1 {
                    self.avatar.layer.borderWidth = 0
                    self.name.alpha = self.inactiveAlpha
                }
            }
        }
    }
}
