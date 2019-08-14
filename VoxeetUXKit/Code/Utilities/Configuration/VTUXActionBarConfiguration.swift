//
//  VTUXActionBarConfiguration.swift
//  VoxeetUXKit
//
//  Created by Corentin Larroque on 05/08/2019.
//  Copyright © 2019 Voxeet. All rights reserved.
//

@objc public class VTUXActionBarConfiguration: NSObject {
    @objc public var displayMute = true
    @objc public var displayCamera = true
    @objc public var displaySpeaker = true
    @objc public var displayScreenShare = false
    @objc public var displayLeave = true
    
    @objc public var overrideMuteOn: UIImage?
    @objc public var overrideMuteOff: UIImage?

    @objc public var overrideCameraOn: UIImage?
    @objc public var overrideCameraOff: UIImage?

    @objc public var overrideSpeakerOn: UIImage?
    @objc public var overrideSpeakerOff: UIImage?
    
    @objc public var overrideScreenShareOn: UIImage?
    @objc public var overrideScreenShareOff: UIImage?
    
    @objc public var overrideLeave: UIImage?
}
