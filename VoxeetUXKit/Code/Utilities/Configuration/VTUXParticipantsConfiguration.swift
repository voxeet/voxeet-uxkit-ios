//
//  VTUXParticipantsConfiguration.swift
//  VoxeetUXKit
//
//  Created by Corentin Larroque on 05/08/2019.
//  Copyright © 2019 Voxeet. All rights reserved.
//

@objcMembers public class VTUXParticipantsConfiguration: NSObject {
    public var speakingColor = UIColor(red: 250/255, green: 190/255, blue: 4/255, alpha: 1)
    public var selectedColor = UIColor(red: 41/255, green: 162/255, blue: 251/255, alpha: 1)
    
    public var displayLeftParticipants = false
    
    @available(iOS, obsoleted: 1, renamed: "speakingColor") // Deprecated: 1.2.7.
    public var speakingUserColor = UIColor(red: 250/255, green: 190/255, blue: 4/255, alpha: 1)
    @available(iOS, obsoleted: 1, renamed: "selectedColor") // Deprecated: 1.2.7.
    public var selectedUserColor = UIColor(red: 41/255, green: 162/255, blue: 251/255, alpha: 1)
    @available(iOS, obsoleted: 1, renamed: "displayLeftParticipants") // Deprecated: 1.2.7.
    public var displayLeftUsers = false
}

@available(iOS, obsoleted: 1, renamed: "VTUXParticipantsConfiguration") // Deprecated: 1.2.7.
@objc public class VTUXUsersConfiguration: NSObject {}
