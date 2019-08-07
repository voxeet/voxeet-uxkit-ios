//
//  VoxeetUXKit.swift
//  VoxeetUXKit
//
//  Created by Corentin Larroque on 15/02/2017.
//  Copyright © 2017 Voxeet. All rights reserved.
//

import UIKit
import VoxeetSDK

// Will soon be deprecated.
@objc public class VoxeetConferenceKit: NSObject {
    @objc public static let shared = VoxeetUXKit.shared
}

/*
 *  MARK: - VoxeetUXKit
 */

@objc public class VoxeetUXKit: NSObject {
    /// Voxeet UX kit singleton.
    @objc public static let shared = VoxeetUXKit()
    
    /// Conference appear animation default starts maximized. If false, the conference will appear minimized.
    @objc public var appearMaximized = true {
        didSet {
            conferenceController.appearMaximized = appearMaximized
        }
    }
    
    /// If true, the conference will behave like a cellular call. if a user hangs up or declines a call, the caller will be disconnected.
    @objc public var telecom = false {
        didSet {
            conferenceController.telecom = telecom
        }
    }
    
    /// Conference controller.
    @objc public var conferenceController = VTUXConferenceController()
    
    /*
     *  MARK: Initialization
     */
    
    override private init() {
        super.init()
        
        // Debug.
        if let version = Bundle(for: type(of: self)).infoDictionary?["CFBundleShortVersionString"],
            let build = Bundle(for: type(of: self)).infoDictionary?["CFBundleVersion"] {
            Swift.print("[VoxeetUXKit] \(version).\(build)")
        }
    }
    
    @objc public func initialize() {}
}
