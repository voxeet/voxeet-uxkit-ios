//
//  VTUXConferenceControllerConfiguration.swift
//  VoxeetUXKit
//
//  Created by Corentin Larroque on 05/08/2019.
//  Copyright © 2019 Voxeet. All rights reserved.
//

@objc public class VTUXConferenceControllerConfiguration: NSObject {
    @objc public var overlay = VTUXOverlayConfiguration()
    @objc public var participants = VTUXParticipantsConfiguration()
    @objc public var speaker = VTUXSpeakerConfiguration()
    @objc public var actionBar = VTUXActionBarConfiguration()
    
    @available(iOS, obsoleted: 1, renamed: "participants") // Deprecated: 1.2.7.
    @objc public var users = VTUXParticipantsConfiguration()
}
