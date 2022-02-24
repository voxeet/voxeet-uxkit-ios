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
        if let actionBarConfig = VoxeetUXKit.shared.conferenceController?.configuration.actionBar {
            muteButton.isHidden = !actionBarConfig.displayMute
            cameraButton.isHidden = !actionBarConfig.displayCamera
            speakerButton.isHidden = !actionBarConfig.displaySpeaker
            screenShareButton.isHidden = !actionBarConfig.displayScreenShare
            leaveButton.isHidden = !actionBarConfig.displayLeave
          leaveButton.setImage(actionBarConfig.overrideLeave ?? UIImage(named: "Leave", in: .module, compatibleWith: nil), for: .normal)
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
            muteButton.isHidden = true
            cameraButton.isHidden = true
            screenShareButton.isHidden = true
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
            
            cameraButton.tag = 0
        }
    }
    
    public func muteButton(state: ButtonState) {
        var customImage: UIImage?
        if let actionBarConfig = VoxeetUXKit.shared.conferenceController?.configuration.actionBar {
            customImage = state == .off ? actionBarConfig.overrideMuteOff : actionBarConfig.overrideMuteOn
        }
        
        toggle(button: muteButton, state: state, defaultImageName: "Mute", customImage: customImage)
    }
    
    public func cameraButton(state: ButtonState) {
        var customImage: UIImage?
        if let actionBarConfig = VoxeetUXKit.shared.conferenceController?.configuration.actionBar {
            customImage = state == .off ? actionBarConfig.overrideCameraOff : actionBarConfig.overrideCameraOn
        }
        
        toggle(button: cameraButton, state: state, defaultImageName: "Camera", customImage: customImage)
    }
    
    public func speakerButton(state: ButtonState) {
        var customImage: UIImage?
        if let actionBarConfig = VoxeetUXKit.shared.conferenceController?.configuration.actionBar {
            customImage = state == .off ? actionBarConfig.overrideSpeakerOff : actionBarConfig.overrideSpeakerOn
        }
        
        toggle(button: speakerButton, state: state, defaultImageName: "Speaker", customImage: customImage)
    }
    
    func speakerButtonHeadphonesState() {
        if let actionBarConfig = VoxeetUXKit.shared.conferenceController?.configuration.actionBar,
           actionBarConfig.overrideSpeakerOff == nil && actionBarConfig.overrideSpeakerOn == nil {
            let image = UIImage(named: "SpeakerOnHeadphones", in: .module, compatibleWith: nil)
            speakerButton.setImage(image, for: .normal)
        } else {
            speakerButton(state: .off)
        }
    }
    
    func speakerButtonBluetoothState() {
        if let actionBarConfig = VoxeetUXKit.shared.conferenceController?.configuration.actionBar,
           actionBarConfig.overrideSpeakerOff == nil && actionBarConfig.overrideSpeakerOn == nil {
          let image = UIImage(named: "SpeakerOnBluetooth", in: .module, compatibleWith: nil)
            speakerButton.setImage(image, for: .normal)
        } else {
            speakerButton(state: .off)
        }
    }
    
    public func screenShareButton(state: ButtonState) {
        var customImage: UIImage?
        if let actionBarConfig = VoxeetUXKit.shared.conferenceController?.configuration.actionBar {
            customImage = state == .off ? actionBarConfig.overrideScreenShareOff : actionBarConfig.overrideScreenShareOn
        }
        
        toggle(button: screenShareButton, state: state, defaultImageName: "ScreenShare", customImage: customImage)
    }
    
    private func toggle(button: UIButton, state: ButtonState, defaultImageName: String, customImage: UIImage?) {
        let defaultImage = UIImage(named: defaultImageName + (state == .off ? "Off" : "On"), in: .module, compatibleWith: nil)
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
