//
//  VTUXConferenceController.swift
//  VoxeetUXKit
//
//  Created by Corentin Larroque on 05/08/2019.
//  Copyright © 2019 Voxeet. All rights reserved.
//

import VoxeetSDK

@objc public class VTUXConferenceController: NSObject {
    private var viewController: ConferenceViewController?
    
    /// Conference configuration.
    @objc public var configuration = VTUXConferenceControllerConfiguration()
    
    /// Conference appear animation default starts maximized. If false, the conference will appear minimized.
    @objc public var appearMaximized = true
    
    /// If true, the conference will behave like a cellular call. if a user hangs up or declines a call, the caller will be disconnected.
    @objc public var telecom = false {
        didSet {
            if telecom {
                NotificationCenter.default.addObserver(self, selector: #selector(participantUpdated), name: .VTParticipantUpdated, object: nil)
            } else {
                NotificationCenter.default.removeObserver(self, name: .VTParticipantUpdated, object: nil)
            }
        }
    }
    
    public override init() {
        super.init()
        
        // Voxeet's socket notifications.
        NotificationCenter.default.addObserver(self, selector: #selector(ownParticipantSwitched), name: .VTOwnParticipantSwitched, object: nil)
        // CallKit notifications.
        NotificationCenter.default.addObserver(self, selector: #selector(callKitSwapped), name: .VTCallKitSwapped, object: nil)
        // Conference state notifications.
        NotificationCenter.default.addObserver(self, selector: #selector(conferenceStateUpdated), name: .VTConferenceStateUpdated, object: nil)
    }
}

/*
 *  MARK: - Notifications: Voxeet
 */

extension VTUXConferenceController {
    @objc private func participantUpdated(notification: NSNotification) {
        // Get JSON.
        guard let userInfo = notification.userInfo?.values.first as? Data else { return }
        
        // Debug.
        print("[VoxeetUXKit] \(String(describing: VoxeetUXKit.self)).\(#function).\(#line)")
        
        // Stop conference if a user decline or leave.
        if let json = try? JSONSerialization.jsonObject(with: userInfo, options: .mutableContainers) {
            if let jsonDict = json as? [String: Any], let status = jsonDict["status"] as? String, status == "DECLINE" || status == "LEFT" {
                // Update conference state label.
                if status == "DECLINE" {
                    self.viewController?.conferenceStateLabel.text = NSLocalizedString("CONFERENCE_STATE_DECLINED", bundle: Bundle(for: type(of: self)), comment: "")
                }
                
                // Leave current conference.
                VoxeetSDK.shared.conference.leave()
            }
        }
    }
    
    @objc private func ownParticipantSwitched(notification: NSNotification) {
        // Debug.
        print("[VoxeetUXKit] \(String(describing: VoxeetUXKit.self)).\(#function).\(#line)")
        
        // Stop the current conference.
        VoxeetSDK.shared.conference.leave()
    }
}

/*
 *  MARK: - Notifications: CallKit
 */

extension VTUXConferenceController {
    @objc private func callKitSwapped(notification: NSNotification) {
        // Remove current conference view from UI before reinitializing it with the new conference's users.
        DispatchQueue.main.async {
            self.viewController?.hide(animated: false) {
                self.viewController?.show(animated: true)
            }
        }
    }
}

/*
 *  MARK: - Notifications: conference state
 */

extension VTUXConferenceController {
    @objc private func conferenceStateUpdated(notification: NSNotification) {
        guard let stateInteger = notification.userInfo?["state"] as? Int, let state = VTConferenceState(rawValue: stateInteger) else {
            return
        }
        
        // Update conference UI.
        viewController?.updateConferenceState(state)
        
        switch state {
        case .connecting:
            if viewController == nil {
                // Create conference UI and adds it to the window.
                let storyboard = UIStoryboard(name: "VoxeetUXKit", bundle: Bundle(for: type(of: self)))
                viewController = storyboard.instantiateInitialViewController() as? ConferenceViewController
                if let vc = viewController {
                    vc.view.translatesAutoresizingMaskIntoConstraints = false
                    guard let window = UIApplication.shared.keyWindow else { return }
                    window.addSubview(vc.view)
                }
                
                // Show conference.
                if appearMaximized {
                    viewController?.show()
                } else {
                    viewController?.view.alpha = 0
                    viewController?.minimize(animated: false)
                    UIView.animate(withDuration: 0.25) {
                        self.viewController?.view.alpha = 1
                    }
                }
            }
        case .disconnected:
            // Hide conference.
            viewController?.hide {
                // Remove conference view from superview.
                self.viewController?.view.removeFromSuperview()
                self.viewController = nil
            }
        default:
            break
        }
    }
}
