//
//  VoxeetConferenceKit.swift
//  VoxeetConferenceKit
//
//  Created by Corentin Larroque on 15/02/2017.
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
    
    // Conference's viewController properties.
    private var vckVC: VCKViewController?
    private let vckVCMaximizeBgColor = UIColor(red: 49/255, green: 63/255, blue: 72/255, alpha: 1)
    private let vckVCMinimizeBgColor = UIColor(red: 14/255, green: 18/255, blue: 21/255, alpha: 1)
    private let vckVCMinimizeSize = CGSize(width: 98, height: 130)
    private var vckVCConstraintsHorizontal = [NSLayoutConstraint]()
    private var vckVCConstraintsVertical = [NSLayoutConstraint]()
    private var vckVCMinimizeVisualConstraintsHorizontal: String!
    private var vckVCMinimizeVisualConstraintsVertical: String!
    
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
        guard vckVC == nil else { return }
        
        // Create conference UI and add it to the window.
        let storyboard = UIStoryboard(name: "VoxeetConferenceKit", bundle: Bundle(for: type(of: self)))
        vckVC = storyboard.instantiateInitialViewController() as? VCKViewController
        guard let vckVC = vckVC else { return }
        vckVC.view.translatesAutoresizingMaskIntoConstraints = false
        guard let window = UIApplication.shared.keyWindow else { return }
        window.addSubview(vckVC.view)
        
        // Default constraints.
        appearConstraints(window: window, vckView: vckVC.view)
        window.layoutIfNeeded()
        
        // Disappear constraints.
        disappearConstraints(window: window, vckView: vckVC.view)
        window.layoutIfNeeded()
        
        // Appear constraints.
        appearConstraints(window: window, vckView: vckVC.view)
        
        // Appear animation.
        CATransaction.begin()
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(controlPoints: 0.43, 0.91, 0.12, 0.95))
        UIView.animate(withDuration: 0.50, animations: {
            window.layoutIfNeeded()
            vckVC.view.backgroundColor = self.vckVCMaximizeBgColor
        }, completion: { _ in
            if !self.appearMaximized {
                self.minimize(animated: true, completion: nil)
            }
        })
        CATransaction.commit()
        
        // Initialize minimize constraints.
        let safeArea = safeAreaInsets()
        vckVCMinimizeVisualConstraintsHorizontal = "H:[vckView(\(vckVCMinimizeSize.width))]-10-|"
        vckVCMinimizeVisualConstraintsVertical = "V:|-\(safeArea.top + 10)-[vckView(\(vckVCMinimizeSize.height))]"
        
        // Close Keyboard.
        closeKeyboard()
    }
    
    private func maximize(animated: Bool = true, completion: (() -> Void)? = nil) {
        guard let vckVC = vckVC, let window = vckVC.view.window else {
            return
        }
        
        // Maximize contraints.
        appearConstraints(window: window, vckView: vckVC.view)
        
        // Maximize animation.
        vckVC.maximize(animated: animated)
        if animated {
            CATransaction.begin()
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(controlPoints: 0.43, 0.91, 0.12, 0.95))
            UIView.animate(withDuration: 0.25, animations: {
                window.layoutIfNeeded()
                vckVC.view.backgroundColor = self.vckVCMaximizeBgColor
            }, completion: { _ in
                completion?()
            })
            CATransaction.commit()
        } else {
            window.layoutIfNeeded()
            self.vckVC!.view.backgroundColor = vckVCMaximizeBgColor
            completion?()
        }
        
        // Reset tap and pan gestures.
        vckVC.view.gestureRecognizers?.removeAll()
        
        // Close Keyboard.
        closeKeyboard()
    }
    
    func minimize(animated: Bool = true, completion: (() -> Void)? = nil) {
        guard let vckVC = vckVC, let window = vckVC.view.window else { return }
        
        // Minimize contraints.
        minimizeConstraints(window: window, vckView: vckVC.view)
        
        // Minimize animation.
        vckVC.minimize(animated: animated)
        if animated {
            CATransaction.begin()
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(controlPoints: 0.43, 0.91, 0.12, 0.95))
            UIView.animate(withDuration: 0.25, animations: {
                window.layoutIfNeeded()
                vckVC.view.backgroundColor = self.vckVCMinimizeBgColor
            }, completion: { _ in
                completion?()
            })
            CATransaction.commit()
        } else {
            window.layoutIfNeeded()
            vckVC.view.backgroundColor = vckVCMinimizeBgColor
            completion?()
        }
        
        // Set tap and pan gestures.
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapGesture(recognizer:)))
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panGesture(recognizer:)))
        vckVC.view.gestureRecognizers = [tap, pan]
    }
    
    func hide(animated: Bool = true, completion: (() -> Void)? = nil) {
        guard let vckVC = vckVC, let window = vckVC.view.window, vckVC.view.tag == 0 else { return }
        
        if animated {
            if vckVC.view.frame.width == vckVCMinimizeSize.width {
                UIView.animate(withDuration: 0.25, animations: {
                    vckVC.view.alpha = 0
                }, completion: { (finished) in
                    // Reset constraints.
                    window.removeConstraints(self.vckVCConstraintsHorizontal + self.vckVCConstraintsVertical)
                    
                    // Remove view from superview.
                    vckVC.view.removeFromSuperview()
                    self.vckVC = nil
                    
                    completion?()
                })
            } else {
                // Disappear constraints.
                disappearConstraints(window: window, vckView: vckVC.view)
                
                vckVC.view.tag = 1 /* Tag locks hide animation. */
                CATransaction.begin()
                CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(controlPoints: 0.43, 0.91, 0.12, 0.95))
                UIView.animate(withDuration: 0.5, animations: {
                    window.layoutIfNeeded()
                }, completion: { (finished) in
                    // Reset constraints.
                    window.removeConstraints(self.vckVCConstraintsHorizontal + self.vckVCConstraintsVertical)
                    
                    // Remove view from superview.
                    vckVC.view.removeFromSuperview()
                    self.vckVC = nil
                    
                    completion?()
                })
                CATransaction.commit()
            }
        } else {
            // Remove view from superview.
            vckVC.view.removeFromSuperview()
            self.vckVC = nil
            
            completion?()
        }
    }
    
    private func appearConstraints(window: UIWindow, vckView: UIView) {
        window.removeConstraints(vckVCConstraintsHorizontal + vckVCConstraintsVertical)
        vckVCConstraintsHorizontal = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[vckView]-0-|", options: [], metrics: nil, views: ["vckView": vckView as Any])
        vckVCConstraintsVertical = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[vckView]-0-|", options: [], metrics: nil, views: ["vckView": vckView as Any])
        window.addConstraints(vckVCConstraintsHorizontal + vckVCConstraintsVertical)
    }
    
    private func disappearConstraints(window: UIWindow, vckView: UIView) {
        window.removeConstraints(vckVCConstraintsHorizontal + vckVCConstraintsVertical)
        vckVCConstraintsHorizontal = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[vckView]-0-|", options: [], metrics: nil, views: ["vckView": vckView as Any])
        vckVCConstraintsVertical = NSLayoutConstraint.constraints(withVisualFormat: "V:[vckView(\(window.frame.height))]-(\(-window.frame.height))-|", options: [], metrics: nil, views: ["vckView": vckView as Any])
        window.addConstraints(vckVCConstraintsHorizontal + vckVCConstraintsVertical)
    }
    
    private func minimizeConstraints(window: UIWindow, vckView: UIView) {
        window.removeConstraints(vckVCConstraintsHorizontal + vckVCConstraintsVertical)
        let safeArea = safeAreaInsets()
        vckVCMinimizeVisualConstraintsVertical = vckVCMinimizeVisualConstraintsVertical ?? "V:|-\(safeArea.top + 10)-[vckView(\(vckVCMinimizeSize.height))]" // Keyboard opening particular case.
        vckVCConstraintsHorizontal = NSLayoutConstraint.constraints(withVisualFormat: vckVCMinimizeVisualConstraintsHorizontal, options: [], metrics: nil, views: ["vckView": vckView as Any])
        vckVCConstraintsVertical = NSLayoutConstraint.constraints(withVisualFormat: vckVCMinimizeVisualConstraintsVertical, options: [], metrics: nil, views: ["vckView": vckView as Any])
        window.addConstraints(vckVCConstraintsHorizontal + vckVCConstraintsVertical)
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
            window.removeConstraints(vckVCConstraintsHorizontal)
            window.removeConstraints(vckVCConstraintsVertical)
            
            vckView.translatesAutoresizingMaskIntoConstraints = true
        case .changed:
            vckView.frame = CGRect(x: point.x - vckView.frame.width / 2, y: point.y - vckView.frame.height / 2, width: vckView.frame.width, height: vckView.frame.height)
        default:
            vckView.translatesAutoresizingMaskIntoConstraints = false
            
            // Update constraints and animate the magnet corner.
            window.removeConstraints(vckVCConstraintsHorizontal)
            window.removeConstraints(vckVCConstraintsVertical)
            generateMinimizeConstraints()
            window.addConstraints(vckVCConstraintsHorizontal)
            window.addConstraints(vckVCConstraintsVertical)
            UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseInOut, animations: {
                window.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    /*
     *  MARK: Other
     */
    
    private func generateMinimizeConstraints() {
        guard let vckView = vckVC?.view, let window = vckView.window else { return }
        let safeArea = safeAreaInsets()
        
        // Generates magnet corner constraints.
        if vckView.frame.origin.x <= window.frame.width / 2 - vckView.frame.width / 2 {
            vckVCMinimizeVisualConstraintsHorizontal = "H:|-\(safeArea.left + 10)-[vckView(\(vckView.frame.width))]"
        } else {
            vckVCMinimizeVisualConstraintsHorizontal = "H:[vckView(\(vckView.frame.width))]-\(safeArea.right + 10)-|"
        }
        if vckView.frame.origin.y <= window.frame.height / 2 - vckView.frame.height / 2 || keyboardOpenned {
            vckVCMinimizeVisualConstraintsVertical = "V:|-\(safeArea.top + 10)-[vckView(\(vckView.frame.height))]"
        } else {
            vckVCMinimizeVisualConstraintsVertical = "V:[vckView(\(vckView.frame.height))]-\(safeArea.bottom + 10)-|"
        }
        
        vckVCConstraintsHorizontal = NSLayoutConstraint.constraints(withVisualFormat: vckVCMinimizeVisualConstraintsHorizontal, options: [], metrics: nil, views: ["vckView": vckView])
        vckVCConstraintsVertical = NSLayoutConstraint.constraints(withVisualFormat: vckVCMinimizeVisualConstraintsVertical, options: [], metrics: nil, views: ["vckView": vckView])
    }
    
    private func safeAreaInsets() -> UIEdgeInsets {
        guard let window = vckVC?.view.window else {
            return .zero
        }
        
        var safeAreaInsets = UIEdgeInsets(top: UIApplication.shared.statusBarFrame.height, left: 0, bottom: 0, right: 0)
        if #available(iOS 11.0, *) {
            safeAreaInsets = window.safeAreaInsets
        }
        
        return safeAreaInsets
    }
    
    private func closeKeyboard() {
        guard let vckVC = vckVC, let window = vckVC.view.window else { return }
        let presentedViewController = window.rootViewController?.presentedViewController ?? window.rootViewController
        presentedViewController?.view.endEditing(true)
    }
}

/*
 *  MARK: - Notifications: Voxeet
 */

extension VoxeetConferenceKit {
    @objc private func participantUpdated(notification: NSNotification) {
        // Get JSON.
        guard let userInfo = notification.userInfo?.values.first as? Data else {
            return
        }
        
        // Debug.
        print("[VoxeetConferenceKit] \(String(describing: VoxeetConferenceKit.self)).\(#function).\(#line)")
        
        // Stop conference if a user decline or leave.
        if let json = try? JSONSerialization.jsonObject(with: userInfo, options: .mutableContainers) {
            if let jsonDict = json as? [String: Any], let status = jsonDict["status"] as? String, status == "DECLINE" || status == "LEFT" {
                // Update conference state label.
                if status == "DECLINE" {
                    self.vckVC?.conferenceStateLabel.text = NSLocalizedString("CONFERENCE_STATE_DECLINED", bundle: Bundle(for: type(of: self)), comment: "")
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
 *  MARK: - Notifications: CallKit
 */

extension VoxeetConferenceKit {
    @objc private func callKitSwapped(notification: NSNotification) {
        // Remove current vckVC from UI before reinitializing it with the new conference's users.
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
            // Show conference.
            show()
            
            // Update conference state label.
            vckVC?.conferenceStateLabel.text = NSLocalizedString("CONFERENCE_STATE_CALLING", bundle: Bundle(for: type(of: self)), comment: "")
            vckVC?.conferenceStateLabel.isHidden = false
        case .connected:
            vckVC?.enableButtons(areEnabled: true)
        case .disconnecting:
            // Update conference state label.
            if vckVC?.conferenceStateLabel.text == nil {
                vckVC?.conferenceStateLabel.text = NSLocalizedString("CONFERENCE_STATE_ENDED", bundle: Bundle(for: type(of: self)), comment: "")
            }
            vckVC?.conferenceStateLabel.isHidden = false
            
            // Hide main user.
            vckVC?.activeSpeakerTimer?.invalidate()
            vckVC?.updateMainUser(user: nil)
            // Hide users collection view.
            vckVC?.usersCollectionView.isHidden = true
            
            // Stop outgoing sound if it was started.
            vckVC?.outgoingSound?.stop()
            vckVC?.outgoingSound = nil
        case .disconnected:
            // Hide conference.
            hide()
        }
    }
}

/*
 *  MARK: - Notifications: constraints updates
 */

extension VoxeetConferenceKit {
    @objc private func applicationDidBecomeActive() {
        guard let vckView = vckVC?.view else { return }
        
        if vckView.frame.width == vckVCMinimizeSize.width {
            reloadMinimizeConstraints()
        } else {
            // Force the vckView to reload all constraints.
            vckView.setNeedsLayout()
            
            // Reset vertical constraint (fix a wrong position when minimized).
            if vckVCMinimizeVisualConstraintsVertical?.range(of: "-|") == nil {
                vckVCMinimizeVisualConstraintsVertical = nil
            }
        }
    }
    
    @objc private func deviceOrientationDidChange() {
        reloadMinimizeConstraints()
    }
    
    private func reloadMinimizeConstraints() {
        guard let vckView = vckVC?.view, let window = vckView.window, vckView.frame.width == vckVCMinimizeSize.width else {
            return
        }
        
        // Update minimized constraints.
        window.removeConstraints(vckVCConstraintsHorizontal + vckVCConstraintsVertical)
        generateMinimizeConstraints()
        window.addConstraints(vckVCConstraintsHorizontal + vckVCConstraintsVertical)
        window.layoutIfNeeded()
    }
}

/*
 *  MARK: - Notifications: keyboard
 */

extension VoxeetConferenceKit {
    @objc private func keyboardWillShow(notification: NSNotification) {
        vckVCMinimizeVisualConstraintsVertical = nil /* Only allow top magnet corners. */
        minimize()
        
        keyboardOpenned = true
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        keyboardOpenned = false
    }
}
