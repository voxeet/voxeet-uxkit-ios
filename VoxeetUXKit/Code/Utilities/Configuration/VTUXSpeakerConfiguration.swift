//
//  VTUXSpeakerConfiguration.swift
//  VoxeetUXKit
//
//  Created by Corentin Larroque on 11/09/2019.
//  Copyright © 2019 Voxeet. All rights reserved.
//

import Foundation

@objc public class VTUXSpeakerConfiguration: NSObject {
    @objc public var speakingColor = UIColor.clear
    
    @available(iOS, obsoleted: 1, renamed: "speakingColor") // Deprecated: 1.2.7.
    @objc public var speakingUserColor = UIColor.clear
}
