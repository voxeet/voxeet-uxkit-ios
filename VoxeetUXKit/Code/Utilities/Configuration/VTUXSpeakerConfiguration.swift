//
//  VTUXSpeakerConfiguration.swift
//  VoxeetUXKit
//
//  Created by Corentin Larroque on 11/09/2019.
//  Copyright © 2019 Voxeet. All rights reserved.
//

@objcMembers public class VTUXSpeakerConfiguration: NSObject {
    public var speakingColor = UIColor.clear
    
    public var videoAspect: VTUXVideoAspect = .fill
    
    @available(iOS, obsoleted: 1, renamed: "speakingColor") // Deprecated: 1.2.7.
    public var speakingUserColor = UIColor.clear
}
