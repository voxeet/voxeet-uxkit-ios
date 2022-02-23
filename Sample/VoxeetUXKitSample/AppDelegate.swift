//
//  AppDelegate.swift
//  VoxeetUXKitSample
//
//  Created by Corentin Larroque on 31/03/2017.
//  Copyright © 2017 Voxeet. All rights reserved.
//

import UIKit
import VoxeetSDK
import VoxeetUXKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Voxeet SDKs initialization.
        VoxeetSDK.shared.initialize(consumerKey: "YOUR_CONSUMER_KEY", consumerSecret: "YOUR_CONSUMER_SECRET")
        VoxeetUXKit.shared.initialize()
        
        // Example of public variables to change the conference behavior.
        VoxeetSDK.shared.notification.push.type = .callKit
        VoxeetSDK.shared.conference.defaultBuiltInSpeaker = true
        VoxeetSDK.shared.conference.defaultVideo = false
        VoxeetUXKit.shared.conferenceController?.appearMaximized = true
        VoxeetUXKit.shared.conferenceController?.telecom = false

        return true
    }
}
