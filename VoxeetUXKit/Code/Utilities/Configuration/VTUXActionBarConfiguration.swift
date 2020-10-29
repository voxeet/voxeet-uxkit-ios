//
//  VTUXActionBarConfiguration.swift
//  VoxeetUXKit
//
//  Created by Corentin Larroque on 05/08/2019.
//  Copyright © 2019 Voxeet. All rights reserved.
//

@objcMembers public class VTUXActionBarConfiguration: NSObject {
    public var displayMute = true
    public var displayCamera = true
    public var displaySpeaker = true
    public var displayScreenShare = false
    public var displayLeave = true
    
    public var overrideMuteOn: UIImage?
    public var overrideMuteOff: UIImage?

    public var overrideCameraOn: UIImage?
    public var overrideCameraOff: UIImage?

    public var overrideSpeakerOn: UIImage?
    public var overrideSpeakerOff: UIImage?
    
    public var overrideScreenShareOn: UIImage?
    public var overrideScreenShareOff: UIImage?
    
    public var overrideLeave: UIImage?
}
