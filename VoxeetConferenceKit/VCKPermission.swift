//
//  VCKPermission.swift
//  VoxeetConferenceKit
//
//  Created by Corentin Larroque on 10/29/18.
//  Copyright © 2018 Voxeet. All rights reserved.
//

import AVFoundation

class VCKPermission {
    @discardableResult class func microphonePermission(controller: UIViewController) -> Bool {
        guard AVAudioSession.sharedInstance().recordPermission == .denied else {
            return true
        }
        
        alert(controller: controller, title: "MICROPHONE_ALERT_TITLE", message: "MICROPHONE_ALERT_MESSAGE", settingsButton: "MICROPHONE_ALERT_BUTTON_SETTINGS", cancelButton: "MICROPHONE_ALERT_BUTTON_CANCEL")
        
        return false
    }
    
    class func cameraPermission(controller: UIViewController, completion: @escaping ((_ authorisation: Bool) -> Void)) {
        if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
            completion(true)
            return
        }
        
        AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
            DispatchQueue.main.async {
                if granted {
                    completion(true)
                } else {
                    alert(controller: controller, title: "CAMERA_ALERT_TITLE", message: "CAMERA_ALERT_MESSAGE", settingsButton: "CAMERA_ALERT_BUTTON_SETTINGS", cancelButton: "CAMERA_ALERT_BUTTON_CANCEL")
                    
                    completion(false)
                }
            }
        })
    }
    
    private class func alert(controller: UIViewController, title: String, message: String, settingsButton: String, cancelButton: String) {
        let alertController = UIAlertController(title: NSLocalizedString(title, bundle: Bundle(for: type(of: controller)), comment: ""), message: NSLocalizedString(message, bundle: Bundle(for: type(of: controller)), comment: ""), preferredStyle: .alert)
        let settingsAction = UIAlertAction(title: NSLocalizedString(settingsButton, bundle: Bundle(for: type(of: controller)), comment: ""), style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(settingsURL) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(settingsURL)
                } else {
                    UIApplication.shared.openURL(settingsURL)
                }
            }
        }
        alertController.addAction(settingsAction)
        alertController.addAction(UIAlertAction(title: NSLocalizedString(cancelButton, bundle: Bundle(for: type(of: controller)), comment: ""), style: .cancel, handler: nil))
        alertController.preferredAction = settingsAction
        controller.present(alertController, animated: true, completion: nil)
    }
}
