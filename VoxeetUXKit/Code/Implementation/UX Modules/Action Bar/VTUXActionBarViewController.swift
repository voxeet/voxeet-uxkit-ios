//
//  VTUXActionBarViewController.swift
//  VoxeetUXKit
//
//  Created by Larroque, Corentin on 02/08/2019.
//  Copyright © 2019 Voxeet. All rights reserved.
//

import VoxeetSDK

@objc public protocol VTUXActionBarViewControllerDelegate {
    func muteAction()
    func cameraAction()
    func switchDeviceSpeakerAction()
    func screenShareAction()
    func leaveAction()
}

@objc public class VTUXActionBarViewController: UIViewController {
    @IBOutlet weak private var muteButton: UIButton!
    @IBOutlet weak private(set) var cameraButton: UIButton!
    @IBOutlet weak private(set) var speakerButton: UIButton!
    @IBOutlet weak private(set) var screenShareButton: UIButton!
    @IBOutlet weak private var leaveButton: UIButton!
    
    @objc public weak var delegate: VTUXActionBarViewControllerDelegate?
    
    enum ButtonState: Int {
        case off
        case on
    }
    
    @objc override public func viewDidLoad() {
        super.viewDidLoad()
        
        // Action bar configuration.
        let actionBarConfiguration = VoxeetUXKit.shared.conferenceController.configuration.actionBar
        muteButton.isHidden = !actionBarConfiguration.displayMute
        muteButton(state: .off)
        cameraButton.isHidden = !actionBarConfiguration.displayCamera
        cameraButton(state: .off)
        speakerButton.isHidden = !actionBarConfiguration.displaySpeaker
        speakerButton(state: .off)
        screenShareButton.isHidden = !actionBarConfiguration.displayScreenShare
        screenShareButton(state: .off)
        leaveButton.isHidden = !actionBarConfiguration.displayLeave
        leaveButton.setImage(actionBarConfiguration.overrideLeave ?? UIImage(named: "HangUp", in: Bundle(for: type(of: self)), compatibleWith: nil), for: .normal)
        
        #if targetEnvironment(simulator)
        cameraButton.isHidden = true
        speakerButton.isHidden = true
        screenShareButton.isHidden = true
        #else
        // Default behavior to check if video is enabled.
        if VoxeetSDK.shared.conference.defaultVideo {
            cameraButton(state: .on)
        }
        // Default behaviour to check if built in spealer is enabled.
        if VoxeetSDK.shared.conference.defaultBuiltInSpeaker {
            speakerButton(state: .on)
        }
        
        // Hide speaker button for devices others than iPhones.
        if UIDevice.current.userInterfaceIdiom != .phone {
            speakerButton.isHidden = true
        }
        // Hide screen share button for devices below iOS 11.
        if #available(iOS 11.0, *) {} else {
            screenShareButton.isHidden = true
        }
        #endif
    }
    
    func enableButtons(_ areEnabled: Bool) {
        let mode = VoxeetSDK.shared.conference.mode
        
        muteButton.isEnabled(mode != .standard ? false : areEnabled, animated: true)
        cameraButton.isEnabled(mode != .standard ? false : areEnabled, animated: true)
        speakerButton.isEnabled(areEnabled, animated: true)
        screenShareButton.isEnabled(mode != .standard ? false : areEnabled, animated: true)
        leaveButton.isEnabled(areEnabled, animated: true)
        
        if mode != .standard {
            muteButton.isHidden = true
            cameraButton.isHidden = true
            screenShareButton.isHidden = true
            
            cameraButton.tag = 0
        }
    }
    
    func muteButton(state: ButtonState) {
        let actionBarConfiguration = VoxeetUXKit.shared.conferenceController.configuration.actionBar
        muteButton.tag = state.rawValue
        
        let customImage = state == .off ? actionBarConfiguration.overrideMuteOff : actionBarConfiguration.overrideMuteOn
        let defaultImage = UIImage(named: "Microphone" + (state == .off ? "On" : "Off"), in: Bundle(for: type(of: self)), compatibleWith: nil)
        
        muteButton.setImage(customImage ?? defaultImage, for: .normal)
    }
    
    func cameraButton(state: ButtonState) {
        let actionBarConfiguration = VoxeetUXKit.shared.conferenceController.configuration.actionBar
        cameraButton.tag = state.rawValue
        
        let customImage = state == .off ? actionBarConfiguration.overrideCameraOff : actionBarConfiguration.overrideCameraOn
        let defaultImage = UIImage(named: "Camera" + (state == .off ? "Off" : "On"), in: Bundle(for: type(of: self)), compatibleWith: nil)
        
        cameraButton.setImage(customImage ?? defaultImage, for: .normal)
    }
    
    func speakerButton(state: ButtonState) {
        let actionBarConfiguration = VoxeetUXKit.shared.conferenceController.configuration.actionBar
        speakerButton.tag = state.rawValue
        
        let customImage = state == .off ? actionBarConfiguration.overrideSpeakerOff : actionBarConfiguration.overrideSpeakerOn
        let defaultImage = UIImage(named: "BuiltInSpeaker" + (state == .off ? "Off" : "On"), in: Bundle(for: type(of: self)), compatibleWith: nil)
        
        speakerButton.setImage(customImage ?? defaultImage, for: .normal)
    }
    
    func screenShareButton(state: ButtonState) {
        let actionBarConfiguration = VoxeetUXKit.shared.conferenceController.configuration.actionBar
        screenShareButton.tag = state.rawValue
        
        let customImage = state == .off ? actionBarConfiguration.overrideScreenShareOff : actionBarConfiguration.overrideScreenShareOn
        let defaultImage = UIImage(named: "ScreenShare" + (state == .off ? "Off" : "On"), in: Bundle(for: type(of: self)), compatibleWith: nil)
        
        screenShareButton.setImage(customImage ?? defaultImage, for: .normal)
    }
    
    /*
     *  MARK: Actions
     */
    
    @IBAction private func muteAction(_ sender: Any) {
        delegate?.muteAction()
    }
    
    @IBAction private func cameraAction(_ sender: Any) {
        delegate?.cameraAction()
    }
    
    @IBAction private func switchDeviceSpeakerAction(_ sender: Any) {
        delegate?.switchDeviceSpeakerAction()
    }
    
    @IBAction private func screenShareAction(_ sender: Any) {
        delegate?.screenShareAction()
    }
    
    @IBAction private func leaveAction(_ sender: Any) {
        delegate?.leaveAction()
    }
}
