//
//  VTUXConferenceControllerConfiguration.swift
//  VoxeetUXKit
//
//  Created by Corentin Larroque on 05/08/2019.
//  Copyright © 2019 Voxeet. All rights reserved.
//

@objcMembers public class VTUXConferenceControllerConfiguration: NSObject {
    public var overlay = VTUXOverlayConfiguration()
    public var participants = VTUXParticipantsConfiguration()
    public var speaker = VTUXSpeakerConfiguration()
    public var actionBar = VTUXActionBarConfiguration()
    
    @available(iOS, obsoleted: 1, renamed: "participants") // Deprecated: 1.2.7.
    public var users = VTUXParticipantsConfiguration()
}
