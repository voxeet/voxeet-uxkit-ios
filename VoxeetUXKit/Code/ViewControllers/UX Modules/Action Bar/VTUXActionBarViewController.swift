//
//  VTUXActionBarViewController.swift
//  VoxeetUXKit
//
//  Created by Corentin Larroque on 02/08/2019.
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
    @IBOutlet weak public var buttonsStackView: UIStackView!
    @IBOutlet weak public var muteButton: UIButton!
    @IBOutlet weak public var cameraButton: UIButton!
    @IBOutlet weak public var speakerButton: UIButton!
    @IBOutlet weak public var screenShareButton: UIButton!
    @IBOutlet weak public var leaveButton: UIButton!
    
    @objc public weak var delegate: VTUXActionBarViewControllerDelegate?
    
    public enum ButtonState: Int {
        case off
        case on
    }
    
    @objc override public func viewDidLoad() {
        super.viewDidLoad()
        
        // Action bar configuration.
        if let actionBarConfiguration = VoxeetUXKit.shared.conferenceController?.configuration.actionBar {
            muteButton.isHidden = !actionBarConfiguration.displayMute
            cameraButton.isHidden = !actionBarConfiguration.displayCamera
            speakerButton.isHidden = !actionBarConfiguration.displaySpeaker
            screenShareButton.isHidden = !actionBarConfiguration.displayScreenShare
            leaveButton.isHidden = !actionBarConfiguration.displayLeave
            leaveButton.setImage(actionBarConfiguration.overrideLeave ?? UIImage(named: "Leave", in: Bundle(for: type(of: self)), compatibleWith: nil), for: .normal)
        }
        muteButton(state: .off)
        cameraButton(state: .off)
        speakerButton(state: .off)
        screenShareButton(state: .off)
        
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
    
    public func buttons(enabled: Bool) {
        let mode = VoxeetSDK.shared.conference.mode
        
        muteButton.isEnabled(mode != .standard ? false : enabled, animated: true)
        cameraButton.isEnabled(mode != .standard ? false : enabled, animated: true)
        speakerButton.isEnabled(enabled, animated: true)
        screenShareButton.isEnabled(mode != .standard ? false : enabled, animated: true)
        leaveButton.isEnabled(enabled, animated: true)
        
        if mode != .standard {
            UIView.animate(withDuration: 0.25, animations: {
                self.muteButton.isHidden = true
                self.cameraButton.isHidden = true
                self.screenShareButton.isHidden = true
            })
            
            cameraButton.tag = 0
        }
    }
    
    public func muteButton(state: ButtonState) {
        var customImage: UIImage?
        if let actionBarConfiguration = VoxeetUXKit.shared.conferenceController?.configuration.actionBar {
            customImage = state == .off ? actionBarConfiguration.overrideMuteOff : actionBarConfiguration.overrideMuteOn
        }
        
        toggle(button: muteButton, state: state, defaultImageName: "Mute", customImage: customImage)
    }
    
    public func cameraButton(state: ButtonState) {
        var customImage: UIImage?
        if let actionBarConfiguration = VoxeetUXKit.shared.conferenceController?.configuration.actionBar {
            customImage = state == .off ? actionBarConfiguration.overrideCameraOff : actionBarConfiguration.overrideCameraOn
        }
        
        toggle(button: cameraButton, state: state, defaultImageName: "Camera", customImage: customImage)
    }
    
    public func speakerButton(state: ButtonState) {
        var customImage: UIImage?
        if let actionBarConfiguration = VoxeetUXKit.shared.conferenceController?.configuration.actionBar {
            customImage = state == .off ? actionBarConfiguration.overrideSpeakerOff : actionBarConfiguration.overrideSpeakerOn
        }
        
        toggle(button: speakerButton, state: state, defaultImageName: "Speaker", customImage: customImage)
    }
    
    public func screenShareButton(state: ButtonState) {
        var customImage: UIImage?
        if let actionBarConfiguration = VoxeetUXKit.shared.conferenceController?.configuration.actionBar {
            customImage = state == .off ? actionBarConfiguration.overrideScreenShareOff : actionBarConfiguration.overrideScreenShareOn
        }
        
        toggle(button: screenShareButton, state: state, defaultImageName: "ScreenShare", customImage: customImage)
    }
    
    private func toggle(button: UIButton, state: ButtonState, defaultImageName: String, customImage: UIImage?) {
        let defaultImage = UIImage(named: defaultImageName + (state == .off ? "Off" : "On"), in: Bundle(for: type(of: self)), compatibleWith: nil)
        
        button.tag = state.rawValue
        button.setImage(customImage ?? defaultImage, for: .normal)
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
