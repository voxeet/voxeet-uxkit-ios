//
//  VoxeetUXKit.swift
//  VoxeetUXKit
//
//  Created by Corentin Larroque on 15/02/2017.
//  Copyright © 2017 Voxeet. All rights reserved.
//

import VoxeetSDK
#if SWIFT_PACKAGE
@_exported import UIKit
@_exported import Foundation
#endif

/*
 *  MARK: - VoxeetUXKit
 */

@objc public class VoxeetUXKit: NSObject {
    /// Voxeet UX kit singleton.
    @objc public static let shared = VoxeetUXKit()
    
    /// Conference controller.
    @objc public private(set) var conferenceController: VTUXConferenceController?
    
    /// Conference appear animation default starts maximized. If false, the conference will appear minimized.
    @available(*, deprecated, renamed: "conferenceController.appearMaximized")
    @objc public var appearMaximized = true {
        didSet {
            initialize()
            conferenceController?.appearMaximized = appearMaximized
        }
    }
    
    /// If true, the conference will behave like a cellular call. if a participant hangs up or declines a call, the caller will be disconnected.
    @available(*, deprecated, renamed: "conferenceController.telecom")
    @objc public var telecom = false {
        didSet {
            initialize()
            conferenceController?.telecom = telecom
        }
    }
    
    /*
     *  MARK: Initialization
     */
    
    override private init() {
        super.init()
        
        let settings = NSDictionary(contentsOfFile: Bundle.module.path(forResource: "settings", ofType: "plist") ?? "")
        // Debug.
        if let version = settings?["UXKitVersion"],
            let build = settings?["UXKitBuild"] {
            Swift.print("[VoxeetUXKit] \(version) (\(build))")
        }
    }
    
    @objc public func initialize() {
        // Init controllers.
        if conferenceController == nil {
            conferenceController = VTUXConferenceController()
        }
    }
}

@available(*, deprecated, renamed: "VoxeetUXKit") // Deprecated: 1.2.7.
@objc public class VoxeetConferenceKit: NSObject {
    @objc public static let shared = VoxeetUXKit.shared
}
