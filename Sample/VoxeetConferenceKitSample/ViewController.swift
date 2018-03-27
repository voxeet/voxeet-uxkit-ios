//
//  ViewController.swift
//  VoxeetConferenceKitSample
//
//  Created by Coco on 31/03/2017.
//  Copyright © 2017 Corentin Larroque. All rights reserved.
//

import UIKit
import VoxeetSDK
import VoxeetConferenceKit

class ViewController: UIViewController {
    @IBOutlet weak private var conferenceNameTextField: UITextField!
    @IBOutlet weak private var participantsPickerView: UIPickerView!
    @IBOutlet weak private var startConferenceButton: UIButton!
    
    private var users = [VTUser]()
    
    let kPickerViewRowNSUserDefaults = "pickerViewRowNSUserDefaults"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up participants.
        users.append(VTUser()) // Logout.
        users.append(VTUser(id: "111", name: "Benoit", photoURL: "https://cdn.voxeet.com/images/team-benoit-senard.png"))
        users.append(VTUser(id: "222", name: "Stephane", photoURL: "https://cdn.voxeet.com/images/team-stephane-giraudie.png"))
        users.append(VTUser(id: "333", name: "Thomas", photoURL: "https://cdn.voxeet.com/images/team-thomas.png"))
        users.append(VTUser(id: "444", name: "Raphael", photoURL: "https://cdn.voxeet.com/images/team-raphael.png"))
        users.append(VTUser(id: "555", name: "Julie", photoURL: "https://cdn.voxeet.com/images/team-julie-egglington.png"))
        users.append(VTUser(id: "666", name: "Alexis", photoURL: "https://cdn.voxeet.com/images/team-alexis.png"))
        users.append(VTUser(id: "777", name: "Barnabé", photoURL: "https://cdn.voxeet.com/images/team-barnabe.png"))
        users.append(VTUser(id: "888", name: "Corentin", photoURL: "https://cdn.voxeet.com/images/team-corentin.png"))
        users.append(VTUser(id: "999", name: "Romain", photoURL: "https://cdn.voxeet.com/images/team-romain.png"))
        
        // Pre-open a session with the previous participant used.
        if let selectedRow = UserDefaults.standard.object(forKey: kPickerViewRowNSUserDefaults) as? Int, selectedRow <= users.count && selectedRow != 0 {
            participantsPickerView.selectRow(selectedRow, inComponent: 0, animated: false)
        }
    }
    
    private func login(user: VTUser) {
        participantsPickerView.isUserInteractionEnabled = false
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        // Open session with the current selected participant.
        VoxeetConferenceKit.shared.openSession(user: user) { (error) in
            self.participantsPickerView.isUserInteractionEnabled = true
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
    
    private func logout(completion: ((NSError?) -> Void)? = nil) {
        participantsPickerView.isUserInteractionEnabled = false
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        VoxeetConferenceKit.shared.closeSession { (error) in
            self.participantsPickerView.isUserInteractionEnabled = true
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            
            completion?(error)
        }
    }
    
    @IBAction func startConferenceAction(_ sender: Any) {
        guard let conferenceID = conferenceNameTextField.text else {
            print("[VoxeetConferenceKitSample] \(String(describing: self)).\(#function).\(#line) - Error: Invalid conference ID")
            return
        }
        
        // Disable startConferenceButton during request network.
        startConferenceButton.isEnabled = false
        
        // Get conference participants without own user.
        let users = self.users.filter({ $0.externalID() != nil && $0.externalID() != self.users[participantsPickerView.selectedRow(inComponent: 0)].externalID() })
        print("test \(users)")
        // Start and join conference.
        VoxeetConferenceKit.shared.startConference(id: conferenceID, users: users, invite: true, success: { (json) in
            // Re-enable startConferenceButton when the request finish.
            self.startConferenceButton.isEnabled = true
            
            // Debug.
            print("[VoxeetConferenceKitSample] \(String(describing: self)).\(#function).\(#line) - Conference successfully started")
        }, fail: { (error) in
            // Debug.
            print("[VoxeetConferenceKitSample] \(String(describing: self)).\(#function).\(#line) - Error: \(error)")
            
            DispatchQueue.main.async {
                // Re-enable startConferenceButton when the request finish.
                self.startConferenceButton.isEnabled = true
                
                // Error message.
                let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
                
                // Stop conference is an error is thrown.
                VoxeetConferenceKit.shared.stopConference()
            }
        })
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
        participantAvatar.kf.setImage(with: URL(string: users[row].externalPhotoURL() ?? ""))
        participantAvatar.layer.cornerRadius = participantAvatar.frame.width / 2
        participantAvatar.layer.masksToBounds = true
        
        // Label name.
        let participantName = UILabel(frame: CGRect(x: participantAvatar.frame.origin.x + participantAvatar.frame.width + 8, y: 0, width: pickerView.frame.width, height: 60))
        participantName.text = users[row].externalName()
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
        
        // Save current picker view.
        UserDefaults.standard.set(row, forKey: kPickerViewRowNSUserDefaults)
        UserDefaults.standard.synchronize()
        
        if row != 0 {
            logout { (error) in
                self.login(user: self.users[row])
            }
        } else {
            logout()
        }
    }
}
