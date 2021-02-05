//
//  ViewController.swift
//  VoxeetUXKitSample
//
//  Created by Corentin Larroque on 31/03/2017.
//  Copyright © 2017 Voxeet. All rights reserved.
//

import UIKit
import VoxeetSDK

/*
 *  MARK: - ViewController
 */

class ViewController: UIViewController {
    
    /*
     *  MARK: Properties
     */
    
    @IBOutlet weak private var container: UIView!
    @IBOutlet weak private var conferenceNameTextField: UITextField!
    @IBOutlet weak private var usernameTextField: UITextField!
    @IBOutlet weak private var startConferenceButton: UIButton!
    @IBOutlet weak private var demoButton: UIButton!
    
    private let kConferenceNameNSUserDefaults = "conferenceNameNSUserDefaults"
    private let kUsernameNSUserDefaults = "usernameNSUserDefaults"
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if let window = UIApplication.shared.keyWindow {
            for subview in window.subviews {
                if subview.accessibilityIdentifier == "ConferenceView" && subview.frame.origin == .zero {
                    return .lightContent
                }
            }
        }
        return .default
    }
    
    /*
     *  MARK: Methods
     */
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Populate textfields using cache.
        if let conferenceName = UserDefaults.standard.object(forKey: kConferenceNameNSUserDefaults) as? String {
            conferenceNameTextField.text = conferenceName
        }
        if let username = UserDefaults.standard.object(forKey: kUsernameNSUserDefaults) as? String {
            usernameTextField.text = username
        }
        
        // Button gradient color.
        let sColor = UIColor(red: 72/255, green: 213/255, blue: 124/255, alpha: 1)
        let eColor = UIColor(red: 192/255, green: 226/255, blue: 73/255, alpha: 1)
        let sPoint = CGPoint(x: 0, y: 1)
        let ePoint = CGPoint(x: 1, y: 0)
        startConferenceButton.applyGradient(colours: [sColor, eColor], startPoint: sPoint, endPoint: ePoint)
        
        // Container's shadow and corner radius.
        container.layer.cornerRadius = 8
        container.layer.shadowOpacity = 0.1
        container.layer.shadowRadius = 16
        container.layer.shadowOffset = CGSize.zero
        container.layer.shadowPath = UIBezierPath(rect: container.bounds).cgPath
        
        // Setup UITextfield for dark mode
        if #available(iOS 13.0, *) {
            conferenceNameTextField.overrideUserInterfaceStyle = .light
            usernameTextField.overrideUserInterfaceStyle = .light
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        conferenceNameTextField.becomeFirstResponder()
    }
    
    /*
     *  MARK: Actions
     */
    
    @IBAction private func startConferenceAction(_ sender: Any? = nil) {
        guard VoxeetSDK.shared.conference.current?.id == nil else { return }
        
        // Get conference alias and username.
        let conferenceNameTextFieldText = conferenceNameTextField.text?.lowercased().replacingOccurrences(of: " ", with: "")
        guard let confAlias = conferenceNameTextFieldText, let username = usernameTextField.text, !confAlias.isEmpty && !username.isEmpty else {
            // Error message.
            let alert = UIAlertController(title: "Error", message: "Invalid conference name/username", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        // Save to cache.
        UserDefaults.standard.set(confAlias, forKey: kConferenceNameNSUserDefaults)
        UserDefaults.standard.set(username, forKey: kUsernameNSUserDefaults)
        UserDefaults.standard.synchronize()
        
        // Disable startConferenceButton during request network.
        startConferenceButton.isEnabled = false
        startConferenceButton.alpha = 0.5
        
        // Connect participant with a random avatar and start conference.
        let avatarID = Int(arc4random_uniform(1000000))
        let participant = VTParticipantInfo(externalID: nil, name: username, avatarURL: "https://gravatar.com/avatar/\(avatarID)?s=200&d=identicon")
        VoxeetSDK.shared.session.open(info: participant) { error in
            self.startConference(alias: confAlias)
        }
    }
    
    private func startConference(alias: String) {
        // Create a conference (with a custom conference alias).
        let options = VTConferenceOptions()
        options.alias = alias
        VoxeetSDK.shared.conference.create(options: options, success: { conference in
            // Join the created conference as listener.
            self.joinConference(conference)
        }, fail: { error in
            // Re-enable startConferenceButton when the request finish.
            self.startConferenceButton.isEnabled = true
            self.startConferenceButton.alpha = 1
            self.errorPopUp(error: error)
        })
    }
    
    private func joinConference(_ conference: VTConference) {
        // Join the created conference.
        VoxeetSDK.shared.conference.join(conference: conference, success: { conference in
            // Re-enable startConferenceButton when the request finish.
            self.startConferenceButton.isEnabled = true
            self.startConferenceButton.alpha = 1
            
            // Debug.
            print("[VoxeetUXKitSample] \(String(describing: self)).\(#function).\(#line) - Conference successfully started")
        }, fail: { error in
            // Re-enable startConferenceButton when the request finish.
            self.startConferenceButton.isEnabled = true
            self.startConferenceButton.alpha = 1
            self.errorPopUp(error: error)
        })
    }
    
    @IBAction private func textFieldEditingChanged(_ sender: Any) {
        guard VoxeetSDK.shared.conference.current?.id == nil else { return }
        
        // Close session.
        VoxeetSDK.shared.session.close()
        
        // Reset cache.
        UserDefaults.standard.set(conferenceNameTextField.text ?? "", forKey: kConferenceNameNSUserDefaults)
        UserDefaults.standard.set(usernameTextField.text ?? "", forKey: kUsernameNSUserDefaults)
        UserDefaults.standard.synchronize()
    }
    
    @IBAction private func demo(_ sender: Any? = nil) {
        guard VoxeetSDK.shared.conference.current?.id == nil else { return }
        
        // Launch demo.
        demoButton.isEnabled = false
        VoxeetSDK.shared.conference.demo() { error in
            self.demoButton.isEnabled = true
            if let error = error {
                self.errorPopUp(error: error)
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        conferenceNameTextField.resignFirstResponder()
        usernameTextField.resignFirstResponder()
    }
    
    /*
     *  MARK: Helpers
     */
    
    private func errorPopUp(error: NSError?) {
        DispatchQueue.main.async {
            var title = "Error"
            if let code = error?.code, code > 0 {
                title = "HTTP \(code)"
            }
            let message = error?.localizedDescription ?? "Unknown"
            
            // Error message.
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}

/*
 *  MARK: - UITextFieldDelegate
 */

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == conferenceNameTextField {
            usernameTextField.becomeFirstResponder()
        } else if textField == usernameTextField {
            usernameTextField.resignFirstResponder()
            startConferenceAction()
        }
        return true
    }
}

/*
 *  MARK: - UIView extension
 */

extension UIView {
    func applyGradient(colours: [UIColor], startPoint: CGPoint, endPoint: CGPoint, locations: [NSNumber]? = nil) {
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = self.bounds
        gradient.colors = colours.map { $0.cgColor }
        gradient.startPoint = startPoint
        gradient.endPoint = endPoint
        gradient.locations = locations
        self.layer.insertSublayer(gradient, at: 0)
    }
}
