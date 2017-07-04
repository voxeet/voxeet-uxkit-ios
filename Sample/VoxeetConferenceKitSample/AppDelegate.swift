//
//  AppDelegate.swift
//  VoxeetConferenceKitSample
//
//  Created by Coco on 31/03/2017.
//  Copyright © 2017 Corentin Larroque. All rights reserved.
//

import UIKit
import VoxeetConferenceKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Example of public variables to change the conference behavior.
        VoxeetConferenceKit.shared.appearMaximized = true
        VoxeetConferenceKit.shared.defaultBuiltInSpeaker = true
        VoxeetConferenceKit.shared.screenAutoLock = false
        
        // Initialization of the Voxeet conference kit (open session later).
        VoxeetConferenceKit.shared.initialize(consumerKey: "consumerKey", consumerSecret: "consumerSecret", automaticallyOpenSession: false)
        
        return true
    }
}

/*
 *  MARK: - Voxeet VoIP push notifications
 */

extension AppDelegate {
    /// Usefull bellow iOS 10.
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        VoxeetConferenceKit.shared.application(application, didReceive: notification)
    }
    
    /// Usefull bellow iOS 10.
    func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, for notification: UILocalNotification, completionHandler: @escaping () -> Void) {
        VoxeetConferenceKit.shared.application(application, handleActionWithIdentifier: identifier, for: notification, completionHandler: completionHandler)
    }
}
