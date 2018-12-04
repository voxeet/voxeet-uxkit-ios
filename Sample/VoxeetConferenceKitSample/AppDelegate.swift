//
//  AppDelegate.swift
//  VoxeetConferenceKitSample
//
//  Created by Coco on 31/03/2017.
//  Copyright © 2017 Corentin Larroque. All rights reserved.
//

import UIKit
import VoxeetSDK
import VoxeetConferenceKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Example of public variables to change the conference behavior.
        VoxeetSDK.shared.conference.defaultBuiltInSpeaker = true
        VoxeetSDK.shared.conference.defaultVideo = false
        VoxeetSDK.shared.callKit = true
        VoxeetConferenceKit.shared.appearMaximized = true
        VoxeetConferenceKit.shared.telecom = false
        
        // Initialization of the Voxeet SDKs.
        VoxeetSDK.shared.initialize(consumerKey: "YOUR_CONSUMER_KEY", consumerSecret: "YOUR_CONSUMER_SECRET", connectSession: false)
        VoxeetConferenceKit.shared.initialize()
        
        return true
    }
}

/*
 *  MARK: - Voxeet VoIP push notifications
 */

extension AppDelegate {
    /// Useful below iOS 10.
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        VoxeetSDK.shared.application(application, didReceive: notification)
    }
    
    /// Useful below iOS 10.
    func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, for notification: UILocalNotification, completionHandler: @escaping () -> Void) {
        VoxeetSDK.shared.application(application, handleActionWithIdentifier: identifier, for: notification, completionHandler: completionHandler)
    }
}
