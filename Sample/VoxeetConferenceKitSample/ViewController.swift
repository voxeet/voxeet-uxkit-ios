//
//  ViewController.swift
//  VoxeetConferenceKitSample
//
//  Created by Coco on 31/03/2017.
//  Copyright © 2017 Corentin Larroque. All rights reserved.
//

import UIKit
import VoxeetSDK

class ViewController: UIViewController {
    @IBOutlet weak private var conferenceNameLabel: UILabel!
    @IBOutlet weak private var conferenceNameTextField: UITextField!
    @IBOutlet weak private var participantsListLabel: UILabel!
    @IBOutlet weak private var participantsPickerView: UIPickerView!
    @IBOutlet weak private var logoutButton: UIButton!
    @IBOutlet weak private var startConferenceButton: UIButton!
    
    private var users = [VTUser]()
    
    private let kConferenceNameNSUserDefaults = "conferenceNameNSUserDefaults"
    private let kPickerViewRowNSUserDefaults = "pickerViewRowNSUserDefaults"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Labels.
        conferenceNameLabel.text = NSLocalizedString("CONFERENCE_NAME_LABEL", comment: "")
        conferenceNameTextField.placeholder = NSLocalizedString("CONFERENCE_NAME_PLACEHOLDER", comment: "")
        participantsListLabel.text = NSLocalizedString("PARTICIPANTS_LIST_LABEL", comment: "")
        logoutButton.setTitle(NSLocalizedString("LOGOUT_BUTTON_TITLE", comment: ""), for: .normal)
        startConferenceButton.setTitle(NSLocalizedString("START_BUTTON_TITLE", comment: ""), for: .normal)
        
        // Set up participants.
        users.append(VTUser(externalID: nil, name: "None", avatarURL: nil)) // Logout.
        users.append(VTUser(externalID: "111", name: "Benoit", avatarURL: "https://cdn.voxeet.com/images/team-benoit-senard.png"))
        users.append(VTUser(externalID: "222", name: "Stephane", avatarURL: "https://cdn.voxeet.com/images/team-stephane-giraudie.png"))
        users.append(VTUser(externalID: "333", name: "Thomas", avatarURL: "https://cdn.voxeet.com/images/team-thomas.png"))
        users.append(VTUser(externalID: "444", name: "Raphael", avatarURL: "https://cdn.voxeet.com/images/team-raphael.png"))
        users.append(VTUser(externalID: "555", name: "Julie", avatarURL: "https://cdn.voxeet.com/images/team-julie-egglington.png"))
        users.append(VTUser(externalID: "666", name: "Alexis", avatarURL: "https://cdn.voxeet.com/images/team-alexis.png"))
        users.append(VTUser(externalID: "777", name: "Barnabé", avatarURL: "https://cdn.voxeet.com/images/team-barnabe.png"))
        users.append(VTUser(externalID: "888", name: "Corentin", avatarURL: "https://cdn.voxeet.com/images/team-corentin.png"))
        users.append(VTUser(externalID: "999", name: "Romain", avatarURL: "https://cdn.voxeet.com/images/team-romain.png"))
        
        // Saved conference name.
        if let conferenceName = UserDefaults.standard.object(forKey: kConferenceNameNSUserDefaults) as? String {
            conferenceNameTextField.text = conferenceName
        }
        
        // Pre-open a session with the previous participant used.
        if let selectedRow = UserDefaults.standard.object(forKey: kPickerViewRowNSUserDefaults) as? Int, selectedRow <= users.count && selectedRow != 0 {
            participantsPickerView.selectRow(selectedRow, inComponent: 0, animated: false)
            login(user: users[selectedRow])
        }
    }
    
    private func login(user: VTUser) {
        participantsPickerView.isUserInteractionEnabled = false
        participantsPickerView.alpha = 0.7
        logoutButton.isEnabled = false
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        // Connect a session with user information.
        VoxeetSDK.shared.session.connect(user: user) { error in
            self.participantsPickerView.isUserInteractionEnabled = true
            self.participantsPickerView.alpha = 1
            self.logoutButton.isEnabled = true
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
    
    private func logout(completion: ((NSError?) -> Void)? = nil) {
        participantsPickerView.isUserInteractionEnabled = false
        participantsPickerView.alpha = 0.7
        logoutButton.isEnabled = false
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        // Remove current saved picker view row.
        UserDefaults.standard.removeObject(forKey: kPickerViewRowNSUserDefaults)
        UserDefaults.standard.synchronize()
        
        // Disconnect current session.
        VoxeetSDK.shared.session.disconnect { error in
            self.participantsPickerView.isUserInteractionEnabled = true
            self.participantsPickerView.alpha = 1
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            
            completion?(error)
        }
    }
    
    @IBAction func logoutAction(_ sender: Any) {
        guard VoxeetSDK.shared.conference.id == nil else {
            return
        }
        
        // Reset picker view and logout.
        participantsPickerView.selectRow(0, inComponent: 0, animated: true)
        logout()
    }
    
    @IBAction func startConferenceAction(_ sender: Any) {
        guard let conferenceID = conferenceNameTextField.text else {
            print("[VoxeetConferenceKitSample] \(String(describing: self)).\(#function).\(#line) - Error: Invalid conference ID")
            return
        }
        guard VoxeetSDK.shared.conference.id == nil else {
            return
        }
        
        // Save conference name.
        UserDefaults.standard.set(conferenceID, forKey: kConferenceNameNSUserDefaults)
        UserDefaults.standard.synchronize()
        
        // Disable startConferenceButton during request network.
        startConferenceButton.isEnabled = false
        
        // Get conference participants without own user.
        let selectedRow = participantsPickerView.selectedRow(inComponent: 0)
        let users = self.users.filter({ $0.externalID != nil && $0.externalID != self.users[selectedRow].externalID })
        
        // Create a conference (with a custom conference alias).
        VoxeetSDK.shared.conference.create(parameters: ["conferenceAlias": conferenceID], success: { (json) in
            guard let confID = json?["conferenceId"] as? String, let isNew = json?["isNew"] as? Bool else {
                return
            }
            
            // Join the created conference.
            VoxeetSDK.shared.conference.join(conferenceID: confID, video: false, userInfo: nil, success: { (json) in
                // Re-enable startConferenceButton when the request finish.
                self.startConferenceButton.isEnabled = true
            }, fail: { (error) in
                // Re-enable startConferenceButton when the request finish.
                self.startConferenceButton.isEnabled = true
                self.errorPopUp(error: error)
            })
            
            // Invite other users if the conference is just created.
            if isNew {
                VoxeetSDK.shared.conference.invite(conferenceID: confID, externalIDs: users.map({ $0.externalID ?? "" }), completion: nil)
            }
        }, fail: { (error) in
            // Re-enable startConferenceButton when the request finish.
            self.startConferenceButton.isEnabled = true
            self.errorPopUp(error: error)
        })
    }
    
    private func errorPopUp(error: Error) {
        DispatchQueue.main.async {
            // Error message.
            let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        conferenceNameTextField.resignFirstResponder()
    }
}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension ViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return users.count
    }
}

extension ViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 60
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let customView = UIView(frame: CGRect(x: 0, y: 0, width: pickerView.frame.width, height: 60))
        
        // Avatar image.
        let participantAvatar = UIImageView(frame: CGRect(x: 8, y: 5, width: 50, height: 50))
        participantAvatar.kf.setImage(with: URL(string: users[row].avatarURL ?? ""))
        participantAvatar.layer.cornerRadius = participantAvatar.frame.width / 2
        participantAvatar.layer.masksToBounds = true
        
        // Label name.
        let participantName = UILabel(frame: CGRect(x: participantAvatar.frame.origin.x + participantAvatar.frame.width + 8, y: 0, width: pickerView.frame.width, height: 60))
        participantName.text = users[row].name
        participantName.font = UIFont.systemFont(ofSize: 14)
        
        customView.addSubview(participantName)
        customView.addSubview(participantAvatar)
        return customView
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if VoxeetSDK.shared.conference.id != nil {
            if let selectedRow = UserDefaults.standard.object(forKey: kPickerViewRowNSUserDefaults) as? Int, selectedRow <= users.count {
                pickerView.selectRow(selectedRow, inComponent: 0, animated: true)
            }
            return
        }
        
        if row != 0 {
            logout { (error) in
                // Save current picker view.
                UserDefaults.standard.set(row, forKey: self.kPickerViewRowNSUserDefaults)
                UserDefaults.standard.synchronize()
                
                self.login(user: self.users[row])
            }
        } else {
            logout()
        }
    }
}
