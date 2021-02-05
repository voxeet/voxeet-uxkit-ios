//
//  OverlayViewController.swift
//  VoxeetUXKit
//
//  Created by Corentin Larroque on 06/08/2019.
//  Copyright © 2019 Voxeet. All rights reserved.
//

class OverlayViewController: UIViewController {
    private let minimizeSize = CGSize(width: 98, height: 130)
    private let minimizeMargin: CGFloat = 10
    
    private var constraintsHorizontal = [NSLayoutConstraint]()
    private var constraintsVertical = [NSLayoutConstraint]()
    private var minimizeVisualConstraintsHorizontal: String!
    private var minimizeVisualConstraintsVertical: String!
    
    private var keyboardOpenned = false
    private var previousInterfaceOrientation: UIInterfaceOrientation!
    
    private let backgroundMaximizedColor: UIColor
    private let backgroundMinimizedColor: UIColor
    
    required init?(coder aDecoder: NSCoder) {
        // Get background color.
        let overlayConfig = VoxeetUXKit.shared.conferenceController?.configuration.overlay
        backgroundMaximizedColor = overlayConfig?.backgroundMaximizedColor ?? .black
        backgroundMinimizedColor = overlayConfig?.backgroundMinimizedColor ?? .black
        
        super.init(coder: aDecoder)
        
        // Constraints updates notifications.
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        previousInterfaceOrientation = UIApplication.shared.statusBarOrientation
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        // Keyboard notifications.
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Background color.
        view.backgroundColor = backgroundMaximizedColor
        
        // Set shadow.
        view.layer.shadowOpacity = 0
        view.layer.shadowRadius = 3
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowPath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: minimizeSize.width, height: minimizeSize.height)).cgPath
    }
    
    /*
     *  MARK: Window animations
     */
    
    func show(animated: Bool = true) {
        guard let window = view.window else { return }
        
        // Default constraints.
        appearConstraints(window: window, view: view)
        window.layoutIfNeeded()
        
        // Disappear constraints.
        disappearConstraints(window: window, view: view)
        window.layoutIfNeeded()
        
        // Appear constraints animation.
        appearConstraints(window: window, view: view)
        CATransaction.begin()
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(controlPoints: 0.43, 0.91, 0.12, 0.95))
        UIView.animate(withDuration: 0.50, animations: {
            window.layoutIfNeeded()
            window.rootViewController?.setNeedsStatusBarAppearanceUpdate()
        }, completion: nil)
        CATransaction.commit()
        
        // Initialize minimize constraints.
        let safeArea = safeAreaInsets()
        minimizeVisualConstraintsHorizontal = "H:[view(\(minimizeSize.width))]-\(safeArea.right + minimizeMargin)-|"
        minimizeVisualConstraintsVertical = "V:|-\(safeArea.top + minimizeMargin)-[view(\(minimizeSize.height))]"
        
        // Close Keyboard.
        closeKeyboard()
    }
    
    func maximize(animated: Bool = true, completion: (() -> Void)? = nil) {
        guard let window = view.window else { return }
        
        // Reset shadow.
        view.layer.shadowOpacity = 0
        
        // Maximize contraints.
        appearConstraints(window: window, view: view)
        
        // Maximize animation.
        if animated {
            CATransaction.begin()
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(controlPoints: 0.43, 0.91, 0.12, 0.95))
            UIView.animate(withDuration: 0.25, animations: {
                window.layoutIfNeeded()
                window.rootViewController?.setNeedsStatusBarAppearanceUpdate()
                self.view.backgroundColor = self.backgroundMaximizedColor
            }, completion: { _ in
                completion?()
            })
            CATransaction.commit()
        } else {
            window.layoutIfNeeded()
            window.rootViewController?.setNeedsStatusBarAppearanceUpdate()
            view.backgroundColor = backgroundMaximizedColor
            completion?()
        }
        
        // Reset tap and pan gestures.
        view.gestureRecognizers?.removeAll()
        
        // Close Keyboard.
        closeKeyboard()
    }
    
    func minimize(animated: Bool = true, completion: (() -> Void)? = nil) {
        guard let window = view.window else { return }
        
        // Set shadow
        view.layer.shadowOpacity = 0.3
        
        // Minimize contraints.
        minimizeConstraints(window: window, view: view)
        
        // Minimize animation.
        if animated {
            CATransaction.begin()
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(controlPoints: 0.43, 0.91, 0.12, 0.95))
            UIView.animate(withDuration: 0.25, animations: {
                window.layoutIfNeeded()
                window.rootViewController?.setNeedsStatusBarAppearanceUpdate()
                self.view.backgroundColor = self.backgroundMinimizedColor
            }, completion: { _ in
                completion?()
            })
            CATransaction.commit()
        } else {
            window.layoutIfNeeded()
            window.rootViewController?.setNeedsStatusBarAppearanceUpdate()
            view.backgroundColor = backgroundMinimizedColor
            completion?()
        }
        
        // Set tap and pan gestures.
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapGesture(recognizer:)))
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panGesture(recognizer:)))
        view.gestureRecognizers = [tap, pan]
    }
    
    func hide(animated: Bool = true, completion: (() -> Void)? = nil) {
        guard let window = view.window, view.tag == 0 else { return }
        
        if animated {
            if view.frame.width == minimizeSize.width {
                UIView.animate(withDuration: 0.25, animations: {
                    window.rootViewController?.setNeedsStatusBarAppearanceUpdate()
                    self.view.alpha = 0
                }, completion: { _ in
                    // Reset constraints.
                    window.removeConstraints(self.constraintsHorizontal + self.constraintsVertical)
                    completion?()
                })
            } else {
                // Disappear constraints.
                disappearConstraints(window: window, view: view)
                
                view.tag = 1 /* Tag locks hide animation */
                CATransaction.begin()
                CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(controlPoints: 0.43, 0.91, 0.12, 0.95))
                UIView.animate(withDuration: 0.5, animations: {
                    window.layoutIfNeeded()
                    window.rootViewController?.setNeedsStatusBarAppearanceUpdate()
                }, completion: { _ in
                    // Reset constraints.
                    window.removeConstraints(self.constraintsHorizontal + self.constraintsVertical)
                    completion?()
                })
                CATransaction.commit()
            }
        } else {
            window.rootViewController?.setNeedsStatusBarAppearanceUpdate()
            completion?()
        }
    }
    
    private func appearConstraints(window: UIWindow, view: UIView) {
        window.removeConstraints(constraintsHorizontal + constraintsVertical)
        constraintsHorizontal = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[view]-0-|", options: [], metrics: nil, views: ["view": view as Any])
        constraintsVertical = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[view]-0-|", options: [], metrics: nil, views: ["view": view as Any])
        window.addConstraints(constraintsHorizontal + constraintsVertical)
    }
    
    private func disappearConstraints(window: UIWindow, view: UIView) {
        window.removeConstraints(constraintsHorizontal + constraintsVertical)
        constraintsHorizontal = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[view]-0-|", options: [], metrics: nil, views: ["view": view as Any])
        constraintsVertical = NSLayoutConstraint.constraints(withVisualFormat: "V:[view(\(window.frame.height))]-(\(-window.frame.height))-|", options: [], metrics: nil, views: ["view": view as Any])
        window.addConstraints(constraintsHorizontal + constraintsVertical)
    }
    
    private func minimizeConstraints(window: UIWindow, view: UIView) {
        window.removeConstraints(constraintsHorizontal + constraintsVertical)
        let safeArea = safeAreaInsets()
        
        // Reset horizontal constraints in case of device orientation.
        if let horizontalConstraints = minimizeVisualConstraintsHorizontal, horizontalConstraints.contains("|-") {
            minimizeVisualConstraintsHorizontal = "H:|-\(safeArea.left + minimizeMargin)-[view(\(minimizeSize.width))]"
        } else {
            minimizeVisualConstraintsHorizontal = "H:[view(\(minimizeSize.width))]-\(safeArea.right + minimizeMargin)-|"
        }
        
        // Reset vertical constraints in case of device orientation.
        let topVerticalConstraints = "V:|-\(safeArea.top + minimizeMargin)-[view(\(minimizeSize.height))]"
        if let verticalConstraints = minimizeVisualConstraintsVertical, verticalConstraints.contains("|-") {
            // Reset safe area in case of device orientation.
            minimizeVisualConstraintsVertical = topVerticalConstraints
        }
        // Keyboard opening particular case.
        minimizeVisualConstraintsVertical = minimizeVisualConstraintsVertical ?? topVerticalConstraints
        
        // Apply minimized constraints.
        constraintsHorizontal = NSLayoutConstraint.constraints(withVisualFormat: minimizeVisualConstraintsHorizontal, options: [], metrics: nil, views: ["view": view as Any])
        constraintsVertical = NSLayoutConstraint.constraints(withVisualFormat: minimizeVisualConstraintsVertical, options: [], metrics: nil, views: ["view": view as Any])
        window.addConstraints(constraintsHorizontal + constraintsVertical)
    }
    
    /*
     *  MARK: Gesture recognizers
     */
    
    @objc func tapGesture(recognizer: UITapGestureRecognizer) {
        maximize()
    }
    
    @objc func panGesture(recognizer: UIPanGestureRecognizer) {
        guard let view = recognizer.view, let window = view.window else {
            return
        }
        let point = recognizer.location(in: view.window)
        
        switch recognizer.state {
        case .began:
            // Reset constraints.
            window.removeConstraints(constraintsHorizontal)
            window.removeConstraints(constraintsVertical)
            
            view.translatesAutoresizingMaskIntoConstraints = true
        case .changed:
            view.frame = CGRect(x: point.x - view.frame.width / 2, y: point.y - view.frame.height / 2, width: view.frame.width, height: view.frame.height)
        default:
            view.translatesAutoresizingMaskIntoConstraints = false
            
            // Update constraints and animate the magnet corner.
            window.removeConstraints(constraintsHorizontal)
            window.removeConstraints(constraintsVertical)
            generateMinimizeConstraints()
            window.addConstraints(constraintsHorizontal)
            window.addConstraints(constraintsVertical)
            UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseInOut, animations: {
                window.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    /*
     *  MARK: Other
     */
    
    private func generateMinimizeConstraints() {
        guard let window = view.window else { return }
        let safeArea = safeAreaInsets()
        
        // Generates magnet corner constraints.
        if view.frame.origin.x <= window.frame.width / 2 - view.frame.width / 2 {
            minimizeVisualConstraintsHorizontal = "H:|-\(safeArea.left + minimizeMargin)-[view(\(view.frame.width))]"
        } else {
            minimizeVisualConstraintsHorizontal = "H:[view(\(view.frame.width))]-\(safeArea.right + minimizeMargin)-|"
        }
        if view.frame.origin.y <= window.frame.height / 2 - view.frame.height / 2 || keyboardOpenned {
            minimizeVisualConstraintsVertical = "V:|-\(safeArea.top + minimizeMargin)-[view(\(view.frame.height))]"
        } else {
            minimizeVisualConstraintsVertical = "V:[view(\(view.frame.height))]-\(safeArea.bottom + minimizeMargin)-|"
        }
        
        constraintsHorizontal = NSLayoutConstraint.constraints(withVisualFormat: minimizeVisualConstraintsHorizontal, options: [], metrics: nil, views: ["view": view as Any])
        constraintsVertical = NSLayoutConstraint.constraints(withVisualFormat: minimizeVisualConstraintsVertical, options: [], metrics: nil, views: ["view": view as Any])
    }
    
    private func safeAreaInsets() -> UIEdgeInsets {
        guard let window = view.window else {
            return .zero
        }
        
        var safeAreaInsets = UIEdgeInsets(top: UIApplication.shared.statusBarFrame.height, left: 0, bottom: 0, right: 0)
        if #available(iOS 11.0, *) {
            safeAreaInsets = window.safeAreaInsets
        }
        
        return safeAreaInsets
    }
    
    private func closeKeyboard() {
        guard let window = view.window else { return }
        let presentedViewController = window.rootViewController?.presentedViewController ?? window.rootViewController
        presentedViewController?.view.endEditing(true)
    }
}

/*
 *  MARK: - Notifications: constraints updates
 */

extension OverlayViewController {
    @objc private func applicationWillEnterForeground() {        
        if view.frame.width == minimizeSize.width {
            reloadMinimizeConstraints()
        } else {
            // Force the view to reload all constraints.
            view.setNeedsLayout()
            
            // Reset vertical constraint (fix a wrong position when minimized).
            if minimizeVisualConstraintsVertical?.range(of: "-|") == nil {
                minimizeVisualConstraintsVertical = nil
            }
        }
    }
    
    @objc private func deviceOrientationDidChange() {
        if previousInterfaceOrientation.isPortrait != UIApplication.shared.statusBarOrientation.isPortrait {
            reloadMinimizeConstraints()
        }
        previousInterfaceOrientation = UIApplication.shared.statusBarOrientation
    }
    
    private func reloadMinimizeConstraints() {
        guard let window = view.window, view.frame.width == minimizeSize.width else {
            return
        }
        
        // Update minimized constraints.
        window.removeConstraints(constraintsHorizontal + constraintsVertical)
        generateMinimizeConstraints()
        window.addConstraints(constraintsHorizontal + constraintsVertical)
        window.layoutIfNeeded()
    }
}

/*
 *  MARK: - Notifications: keyboard
 */

extension OverlayViewController {
    @objc private func keyboardWillShow(notification: NSNotification) {
        keyboardOpenned = true
        
        minimizeVisualConstraintsVertical = nil /* Only allow top magnet corners. */
        UIView.animate(withDuration: 0.25, animations: {
            self.reloadMinimizeConstraints()
        })
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        keyboardOpenned = false
    }
}
