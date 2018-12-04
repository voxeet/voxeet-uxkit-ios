//
//  VoxeetConferenceKit.swift
//  VoxeetConferenceKit
//
//  Created by Coco on 15/02/2017.
//  Copyright © 2017 Voxeet. All rights reserved.
//

import UIKit
import VoxeetSDK

/*
 *  MARK: - VoxeetConferenceKit
 */

@objc public class VoxeetConferenceKit: NSObject {
    /// Voxeet conference kit singleton.
    @objc public static let shared = VoxeetConferenceKit()
    
    /// Conference appear animation default starts maximized. If false, the conference will appear minimized.
    @objc public var appearMaximized = true
    
    /// If true, the conference will behave like a cellular call, if a user hangs up or decline the caller will be disconnected.
    @objc public var telecom = false {
        didSet {
            if telecom {
                NotificationCenter.default.addObserver(self, selector: #selector(participantUpdated), name: .VTParticipantUpdated, object: nil)
            } else {
                NotificationCenter.default.removeObserver(self, name: .VTParticipantUpdated, object: nil)
            }
        }
    }
    
    // Conference's viewController properties.
    private var vckController: VCKViewController?
    private let vckControllerMinimizeSize = CGSize(width: 98, height: 130)
    private var vckControllerConstraintsHorizontal = [NSLayoutConstraint]()
    private var vckControllerConstraintsVertical = [NSLayoutConstraint]()
    private var vckControllerMinimizeVisualConstraintsHorizontal: String!
    private var vckControllerMinimizeVisualConstraintsVertical: String!
    private var keyboardOpenned = false
    
    /*
     *  MARK: Initialization
     */
    
    override private init() {
        super.init()
        
        // Voxeet's socket notifications.
        NotificationCenter.default.addObserver(self, selector: #selector(ownParticipantSwitched), name: .VTOwnParticipantSwitched, object: nil)
        // CallKit notifications.
        NotificationCenter.default.addObserver(self, selector: #selector(callKitSwapped), name: .VTCallKitSwapped, object: nil)
        // Conference state notifications.
        NotificationCenter.default.addObserver(self, selector: #selector(conferenceStateUpdated), name: .VTConferenceStateUpdated, object: nil)
        
        // Constraints updates notifications.
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        // Keyboard notifications.
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // Debug.
        if let version = Bundle(for: type(of: self)).infoDictionary?["CFBundleShortVersionString"],
            let build = Bundle(for: type(of: self)).infoDictionary?["CFBundleVersion"] {
            Swift.print("[VoxeetConferenceKit] \(version).\(build)")
        }
    }
    
    @objc public func initialize() {}
    
    /*
     *  MARK: Window animations
     */
    
    private func show(animated: Bool = true) {
        guard vckController == nil else { return }
        
        // Creates the conference UI and adds it to the window.
        let storyboard = UIStoryboard(name: "VoxeetConferenceKit", bundle: Bundle(for: type(of: self)))
        vckController = storyboard.instantiateInitialViewController() as? VCKViewController
        vckController!.view.translatesAutoresizingMaskIntoConstraints = false
        vckController!.view.alpha = 0
        guard let window = UIApplication.shared.keyWindow else { return }
        window.addSubview(vckController!.view)
        
        // Appear constraints.
        let widthConstraint = NSLayoutConstraint(item: vckController!.view, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: vckControllerMinimizeSize.width)
        let heightConstraint = NSLayoutConstraint(item: vckController!.view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: vckControllerMinimizeSize.height)
        let xConstraint = NSLayoutConstraint(item: vckController!.view, attribute: .centerX, relatedBy: .equal, toItem: window, attribute: .centerX, multiplier: 1, constant: 0)
        let yConstraint = NSLayoutConstraint(item: vckController!.view, attribute: .centerY, relatedBy: .equal, toItem: window, attribute: .centerY, multiplier: 1, constant: 0)
        window.addConstraints([widthConstraint, heightConstraint, xConstraint, yConstraint])
        window.layoutIfNeeded()
        window.removeConstraints([widthConstraint, heightConstraint, xConstraint, yConstraint])
        
        // Initialize minimize constraints.
        let safeArea = safeAreaInsets()
        vckControllerMinimizeVisualConstraintsHorizontal = "H:[vckView(\(vckControllerMinimizeSize.width))]-10-|"
        vckControllerMinimizeVisualConstraintsVertical = "V:|-\(safeArea.top + 10)-[vckView(\(vckControllerMinimizeSize.height))]"
        
        // Start animation with a minimized state and with a fade animation.
        minimize(animated: true)
        if animated {
            UIView.animate(withDuration: 0.10, delay: 0, options: .curveLinear, animations: {
                self.vckController!.view.alpha = 1
            }, completion: nil)
        } else {
            vckController!.view.alpha = 1
        }
        
        // Then if the `appear maximized` is wanted, extends the conference view to fullscreen.
        if appearMaximized {
            // Show conference view.
            maximize(animated: animated)
        }
    }
    
    private func maximize(animated: Bool = true, completion: (() -> Void)? = nil) {
        guard let vckController = vckController, let window = vckController.view.window else {
            return
        }
        vckController.maximize(animated: animated)
        
        // Hide current keyboard.
        let presentedViewController = window.rootViewController?.presentedViewController ?? window.rootViewController
        presentedViewController?.view.endEditing(true)
        
        // Reset tap and pan gestures.
        vckController.view.gestureRecognizers?.removeAll()
        
        // Reset constraints.
        window.removeConstraints(vckControllerConstraintsHorizontal)
        window.removeConstraints(vckControllerConstraintsVertical)
        
        // Add maximize contraints.
        vckControllerConstraintsHorizontal = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[vckView]-0-|", options: [], metrics: nil, views: ["vckView": vckController.view])
        vckControllerConstraintsVertical = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[vckView]-0-|", options: [], metrics: nil, views: ["vckView": vckController.view])
        window.addConstraints(vckControllerConstraintsHorizontal)
        window.addConstraints(vckControllerConstraintsVertical)
        
        // Maximize animation.
        if animated {
            UIView.animate(withDuration: 0.20, delay: 0, options: .curveEaseInOut, animations: {
                window.layoutIfNeeded()
                self.vckController!.view.backgroundColor = UIColor(red: 49/255, green: 63/255, blue: 72/255, alpha: 1)
            }, completion: { _ in
                completion?()
            })
        } else {
            window.layoutIfNeeded()
            self.vckController!.view.backgroundColor = UIColor(red: 49/255, green: 63/255, blue: 72/255, alpha: 1)
            completion?()
        }
    }
    
    func minimize(animated: Bool = true, completion: (() -> Void)? = nil) {
        guard let vckController = vckController, let window = vckController.view.window else {
            return
        }
        vckController.minimize(animated: animated)
        
        // Set tap and pan gestures.
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapGesture(recognizer:)))
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panGesture(recognizer:)))
        vckController.view.gestureRecognizers = [tap, pan]
        
        // Reset constraints.
        window.removeConstraints(vckControllerConstraintsHorizontal)
        window.removeConstraints(vckControllerConstraintsVertical)
        
        // Add minimize contraints.
        let safeArea = safeAreaInsets()
        vckControllerMinimizeVisualConstraintsVertical = vckControllerMinimizeVisualConstraintsVertical ?? "V:|-\(safeArea.top + 10)-[vckView(\(vckControllerMinimizeSize.height))]" // Keyboard opening particular case.
        vckControllerConstraintsHorizontal = NSLayoutConstraint.constraints(withVisualFormat: vckControllerMinimizeVisualConstraintsHorizontal, options: [], metrics: nil, views: ["vckView": vckController.view])
        vckControllerConstraintsVertical = NSLayoutConstraint.constraints(withVisualFormat: vckControllerMinimizeVisualConstraintsVertical, options: [], metrics: nil, views: ["vckView": vckController.view])
        window.addConstraints(vckControllerConstraintsHorizontal)
        window.addConstraints(vckControllerConstraintsVertical)
        
        // Minimize animation.
        if animated {
            UIView.animate(withDuration: 0.20, delay: 0, options: .curveEaseInOut, animations: {
                window.layoutIfNeeded()
                vckController.view.backgroundColor = UIColor(red: 14/255, green: 18/255, blue: 21/255, alpha: 1)
            }, completion: { _ in
                completion?()
            })
        } else {
            window.layoutIfNeeded()
            vckController.view.backgroundColor = UIColor(red: 14/255, green: 18/255, blue: 21/255, alpha: 1)
            completion?()
        }
    }
    
    func hide(animated: Bool = true, completion: (() -> Void)? = nil) {
        guard let vckController = vckController, let window = vckController.view.window, vckController.view.tag == 0 else {
            return
        }
        
        var widthConstraint = NSLayoutConstraint()
        var heightConstraint = NSLayoutConstraint()
        var xConstraint = NSLayoutConstraint()
        var yConstraint = NSLayoutConstraint()
        
        // Reset previous constraints.
        window.removeConstraints(self.vckControllerConstraintsHorizontal)
        window.removeConstraints(self.vckControllerConstraintsVertical)
        
        if animated {
            // Disappear constraints.
            widthConstraint = NSLayoutConstraint(item: vckController.view, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: vckControllerMinimizeSize.width)
            heightConstraint = NSLayoutConstraint(item: vckController.view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: vckControllerMinimizeSize.height)
            xConstraint = NSLayoutConstraint(item: vckController.view, attribute: .centerX, relatedBy: .equal, toItem: window, attribute: .centerX, multiplier: 1, constant: 0)
            yConstraint = NSLayoutConstraint(item: vckController.view, attribute: .centerY, relatedBy: .equal, toItem: window, attribute: .centerY, multiplier: 1, constant: 0)
            window.addConstraints([widthConstraint, heightConstraint, xConstraint, yConstraint])
            
            vckController.view.tag = 1 // Lock hide animation.
            UIView.animate(withDuration: 0.20, animations: {
                vckController.view.alpha = 0
                window.layoutIfNeeded()
            }, completion: { (finished) in
                // Reset constraints.
                window.removeConstraints([widthConstraint, heightConstraint, xConstraint, yConstraint])
                window.removeConstraints(self.vckControllerConstraintsHorizontal)
                window.removeConstraints(self.vckControllerConstraintsVertical)
                
                // Remove the view from the superview.
                vckController.view.removeFromSuperview()
                self.vckController = nil
                
                completion?()
            })
        } else {
            // Remove the view from the superview.
            vckController.view.removeFromSuperview()
            self.vckController = nil
            
            completion?()
        }
    }
    
    /*
     *  MARK: Gesture recognizers
     */
    
    @objc private func tapGesture(recognizer: UITapGestureRecognizer) {
        maximize()
    }
    
    @objc private func panGesture(recognizer: UIPanGestureRecognizer) {
        guard let vckView = recognizer.view, let window = vckView.window else {
            return
        }
        let point = recognizer.location(in: vckView.window)
        
        switch recognizer.state {
        case .began:
            // Reset constraints.
            window.removeConstraints(vckControllerConstraintsHorizontal)
            window.removeConstraints(vckControllerConstraintsVertical)
            
            vckView.translatesAutoresizingMaskIntoConstraints = true
        case .changed:
            vckView.frame = CGRect(x: point.x - vckView.frame.width / 2, y: point.y - vckView.frame.height / 2, width: vckView.frame.width, height: vckView.frame.height)
        default:
            vckView.translatesAutoresizingMaskIntoConstraints = false
            
            // Update constraints and animate the magnet corner.
            window.removeConstraints(vckControllerConstraintsHorizontal)
            window.removeConstraints(vckControllerConstraintsVertical)
            generateMinimizeConstraints()
            window.addConstraints(vckControllerConstraintsHorizontal)
            window.addConstraints(vckControllerConstraintsVertical)
            UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseInOut, animations: {
                window.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    /*
     *  MARK: Other
     */
    
    private func generateMinimizeConstraints() {
        guard let vckView = vckController?.view, let window = vckView.window else {
            return
        }
        let safeArea = safeAreaInsets()
        
        // Generates magnet corner constraints.
        if vckView.frame.origin.x <= window.frame.width / 2 - vckView.frame.width / 2 {
            vckControllerMinimizeVisualConstraintsHorizontal = "H:|-\(safeArea.left + 10)-[vckView(\(vckView.frame.width))]"
        } else {
            vckControllerMinimizeVisualConstraintsHorizontal = "H:[vckView(\(vckView.frame.width))]-\(safeArea.right + 10)-|"
        }
        if vckView.frame.origin.y <= window.frame.height / 2 - vckView.frame.height / 2 || keyboardOpenned {
            vckControllerMinimizeVisualConstraintsVertical = "V:|-\(safeArea.top + 10)-[vckView(\(vckView.frame.height))]"
        } else {
            vckControllerMinimizeVisualConstraintsVertical = "V:[vckView(\(vckView.frame.height))]-\(safeArea.bottom + 10)-|"
        }
        
        vckControllerConstraintsHorizontal = NSLayoutConstraint.constraints(withVisualFormat: vckControllerMinimizeVisualConstraintsHorizontal, options: [], metrics: nil, views: ["vckView": vckView])
        vckControllerConstraintsVertical = NSLayoutConstraint.constraints(withVisualFormat: vckControllerMinimizeVisualConstraintsVertical, options: [], metrics: nil, views: ["vckView": vckView])
    }
    
    private func safeAreaInsets() -> UIEdgeInsets {
        guard let window = vckController?.view.window else {
            return .zero
        }
        
        var safeAreaInsets = UIEdgeInsets(top: UIApplication.shared.statusBarFrame.height, left: 0, bottom: 0, right: 0)
        if #available(iOS 11.0, *) {
            safeAreaInsets = window.safeAreaInsets
        }
        
        return safeAreaInsets
    }
}

/*
 *  MARK: - Notifications: voxeet's socket
 */

extension VoxeetConferenceKit {
    @objc func participantUpdated(notification: NSNotification) {
        // Get JSON.
        guard let userInfo = notification.userInfo?.values.first as? Data else {
            return
        }
        
        // Debug.
        print("[VoxeetConferenceKit] \(String(describing: VoxeetConferenceKit.self)).\(#function).\(#line)")
        
        // Stop the conference if the user decline or left the conference.
        if let json = try? JSONSerialization.jsonObject(with: userInfo, options: .mutableContainers) {
            if let jsonDict = json as? [String: Any], let status = jsonDict["status"] as? String, status == "DECLINE" || status == "LEFT" {
                // Update the conference state label.
                if status == "DECLINE" {
                    self.vckController?.conferenceStateLabel.text = NSLocalizedString("CONFERENCE_STATE_DECLINED", bundle: Bundle(for: type(of: self)), comment: "")
                }
                
                VoxeetSDK.shared.conference.leave()
            }
        }
    }
    
    @objc private func ownParticipantSwitched(notification: NSNotification) {
        // Debug.
        print("[VoxeetConferenceKit] \(String(describing: VoxeetConferenceKit.self)).\(#function).\(#line)")
        
        // Stop the current conference.
        VoxeetSDK.shared.conference.leave()
    }
}

/*
 *  MARK: - Notifications: callKit
 */

extension VoxeetConferenceKit {
    @objc func callKitSwapped(notification: NSNotification) {
        // Remove current vckController from UI before reinitializing it with the new conference's users.
        DispatchQueue.main.async {
            self.hide(animated: false) {
                self.show(animated: true)
            }
        }
    }
}

/*
 *  MARK: - Notifications: conference state
 */

extension VoxeetConferenceKit {
    @objc private func conferenceStateUpdated(notification: NSNotification) {
        guard let stateInteger = notification.userInfo?["state"] as? Int, let state = VTConferenceState(rawValue: stateInteger) else {
            return
        }
        
        switch state {
        case .connecting:
            // Show the conference.
            show()
            
            // Update the conference state label.
            vckController?.conferenceStateLabel.text = NSLocalizedString("CONFERENCE_STATE_CALLING", bundle: Bundle(for: type(of: self)), comment: "")
            vckController?.conferenceStateLabel.isHidden = false
        case .connected:
            break
        case .disconnecting:
            // Update the conference state label.
            if vckController?.conferenceStateLabel.text == nil {
                vckController?.conferenceStateLabel.text = NSLocalizedString("CONFERENCE_STATE_ENDED", bundle: Bundle(for: type(of: self)), comment: "")
            }
            vckController?.conferenceStateLabel.isHidden = false
            
            // Hidding main user.
            vckController?.activeSpeakerTimer?.invalidate()
            vckController?.updateMainUser(user: nil)
            
            // Stop outgoing sound if it started and play hang up sound.
            vckController?.outgoingSound?.stop()
            vckController?.outgoingSound = nil
            // try? vckController?.hangUpSound?.play()
        case .disconnected:
            // Hide animation.
            hide()
        }
    }
}

/*
 *  MARK: - Notifications: constraints updates
 */

extension VoxeetConferenceKit {
    @objc private func applicationDidBecomeActive() {
        guard let vckView = vckController?.view else {
            return
        }
        
        if vckView.frame.width == vckControllerMinimizeSize.width {
            reloadMinimizeConstraints()
        } else {
            // Force the vckView to reload all constraints.
            vckView.setNeedsLayout()
            
            // Reset vertical constraint (wrong position when minimized).
            if vckControllerMinimizeVisualConstraintsVertical?.range(of: "-|") == nil {
                vckControllerMinimizeVisualConstraintsVertical = nil
            }
        }
    }
    
    @objc private func deviceOrientationDidChange() {
        reloadMinimizeConstraints()
    }
    
    private func reloadMinimizeConstraints() {
        guard let vckView = vckController?.view, let window = vckView.window, vckView.frame.width == vckControllerMinimizeSize.width else {
            return
        }
        
        // Update minimized constraints.
        window.removeConstraints(vckControllerConstraintsHorizontal)
        window.removeConstraints(vckControllerConstraintsVertical)
        generateMinimizeConstraints()
        window.addConstraints(vckControllerConstraintsHorizontal)
        window.addConstraints(vckControllerConstraintsVertical)
        
        window.layoutIfNeeded()
    }
}

/*
 *  MARK: - Notifications: keyboard
 */

extension VoxeetConferenceKit {
    @objc func keyboardWillShow(notification: NSNotification) {
        vckControllerMinimizeVisualConstraintsVertical = nil // Only allow top magnet corners.
        minimize()
        
        keyboardOpenned = true
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        keyboardOpenned = false
    }
}
