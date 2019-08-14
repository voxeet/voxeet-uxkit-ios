//
//  VTUXConferenceControllerConfiguration.swift
//  VoxeetUXKit
//
//  Created by Corentin Larroque on 05/08/2019.
//  Copyright © 2019 Voxeet. All rights reserved.
//

@objc public class VTUXConferenceControllerConfiguration: NSObject {
    @objc public var overlay = VTUXOverlayConfiguration()
    @objc public var users = VTUXUsersConfiguration()
    @objc public var actionBar = VTUXActionBarConfiguration()
}
