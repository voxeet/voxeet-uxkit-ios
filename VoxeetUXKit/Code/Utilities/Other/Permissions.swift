//
//  Permissions.swift
//  VoxeetUXKit
//
//  Created by Corentin Larroque on 10/29/18.
//  Copyright © 2018 Voxeet. All rights reserved.
//

import AVFoundation

class Permissions {
    @discardableResult class func microphone(controller: UIViewController) -> Bool {
        guard AVAudioSession.sharedInstance().recordPermission == .denied else {
            return true
        }
        
        alert(controller: controller, title: "VTUX_MICROPHONE_ALERT_TITLE", message: "VTUX_MICROPHONE_ALERT_MESSAGE", settingsButton: "VTUX_MICROPHONE_ALERT_BUTTON_SETTINGS", cancelButton: "VTUX_MICROPHONE_ALERT_BUTTON_CANCEL")
        
        return false
    }
    
    class func camera(controller: UIViewController, completion: @escaping ((_ authorisation: Bool) -> Void)) {
        if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
            completion(true)
            return
        }
        
        AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
            DispatchQueue.main.async {
                if granted {
                    completion(true)
                } else {
                    alert(controller: controller, title: "VTUX_CAMERA_ALERT_TITLE", message: "VTUX_CAMERA_ALERT_MESSAGE", settingsButton: "VTUX_CAMERA_ALERT_BUTTON_SETTINGS", cancelButton: "VTUX_CAMERA_ALERT_BUTTON_CANCEL")
                    
                    completion(false)
                }
            }
        })
    }
    
    private class func alert(controller: UIViewController, title: String, message: String, settingsButton: String, cancelButton: String) {
        let alertController = UIAlertController(title: VTUXLocalized.string(title), message: VTUXLocalized.string(message), preferredStyle: .alert)
        let settingsAction = UIAlertAction(title: VTUXLocalized.string(settingsButton), style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(settingsURL) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(settingsURL)
                } else {
                    UIApplication.shared.openURL(settingsURL)
                }
            }
        }
        alertController.addAction(settingsAction)
        alertController.addAction(UIAlertAction(title: VTUXLocalized.string(cancelButton), style: .cancel, handler: nil))
        alertController.preferredAction = settingsAction
        controller.present(alertController, animated: true, completion: nil)
    }
}
