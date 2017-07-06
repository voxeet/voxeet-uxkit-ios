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

// NSUserDefaults.
let pickerViewRowNSUserDefaults = "pickerViewRowNSUserDefaults"

class ViewController: UIViewController {
    @IBOutlet weak private var conferenceNameTextField: UITextField!
    @IBOutlet weak private var participantsPickerView: UIPickerView!
    
    fileprivate var participants = [VoxeetParticipant]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up participants.
        participants.append(VoxeetParticipant(id: "", name: "None", avatarURL: nil)) // Logout participant.
        participants.append(VoxeetParticipant(id: "1", name: "Benoit", avatarURL: URL(string: "https://cdn.voxeet.com/images/team-benoit-senard.png")))
        participants.append(VoxeetParticipant(id: "2", name: "Stephane", avatarURL: URL(string: "https://cdn.voxeet.com/images/team-stephane-giraudie.png")))
        participants.append(VoxeetParticipant(id: "3", name: "Corentin", avatarURL: URL(string: "https://cdn.voxeet.com/images/team-corentin.png")))
        participants.append(VoxeetParticipant(id: "4", name: "Thomas", avatarURL: URL(string: "https://media.licdn.com/mpr/mpr/shrinknp_200_200/AAEAAQAAAAAAAAayAAAAJDQ4MTY5NGI3LWM0NjEtNGQ3Ny1iNjBjLTIzNTYwMDVjNjQzYg.jpg")))
        
        // Pre-open a session with the previous participant used.
        if let selectedRow = UserDefaults.standard.object(forKey: pickerViewRowNSUserDefaults) as? Int, selectedRow <= participants.count && selectedRow != 0 {
            participantsPickerView.selectRow(selectedRow, inComponent: 0, animated: false)
            
            // Logs your user to Voxeet in order to receive VoIP push notifications or any Voxeet notifications before starting a conference.
            login(row: selectedRow)
        }
    }
    
    fileprivate func login(row: Int) {
        participantsPickerView.isUserInteractionEnabled = false
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        // Close the previous session if there is one before oppening a new.
        VoxeetConferenceKit.shared.closeSession { (error) in
            // Open session with the current selected participant.
            VoxeetConferenceKit.shared.openSession(participant: self.participants[row]) { (error) in
                self.participantsPickerView.isUserInteractionEnabled = true
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
        }
    }
    
    fileprivate func logout() {
        participantsPickerView.isUserInteractionEnabled = false
        UIApplication.shared.isNetworkActivityIndicatorVisible = true

        VoxeetConferenceKit.shared.closeSession { (error) in
            self.participantsPickerView.isUserInteractionEnabled = true
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
    
    @IBAction func joinConferenceAction(_ sender: Any) {
        guard let conferenceID = conferenceNameTextField.text else {
            print("[VoxeetConferenceKitSample] \(String(describing: self)).\(#function).\(#line) - Error: Invalid conference ID")
            return
        }
        // Remove own participant.
        let participants = self.participants.filter({ !$0.id.isEmpty && $0.id != self.participants[UserDefaults.standard.integer(forKey: pickerViewRowNSUserDefaults)].id })
        
        // Initialize conference.
        VoxeetConferenceKit.shared.initializeConference(id: conferenceID, participants: participants)
        
        // Start and join conference.
        VoxeetConferenceKit.shared.startConference(sendInvitation: true, success: { (json) in
            // Debug.
            print("[VoxeetConferenceKitSample] \(String(describing: self)).\(#function).\(#line) - Conference successfully started")
        }, fail: { (error) in
            // Debug.
            print("[VoxeetConferenceKitSample] \(String(describing: self)).\(#function).\(#line) - Error: \(error)")
            
            // Error message.
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Error", message: "Something went wrong with the conference.", preferredStyle: UIAlertControllerStyle.alert)
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
        return participants.count
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
        participantAvatar.kf.setImage(with: participants[row].avatarURL)
        participantAvatar.layer.cornerRadius = participantAvatar.frame.width / 2
        participantAvatar.layer.masksToBounds = true
        
        // Label name.
        let participantName = UILabel(frame: CGRect(x: participantAvatar.frame.origin.x + participantAvatar.frame.width + 8, y: 0, width: pickerView.frame.width, height: 60))
        participantName.text = participants[row].name
        participantName.font = UIFont.systemFont(ofSize: 14)
        
        customView.addSubview(participantName)
        customView.addSubview(participantAvatar)
        
        return customView
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if VoxeetSDK.shared.conference.hasLiveConference() != nil {
            if let selectedRow = UserDefaults.standard.object(forKey: pickerViewRowNSUserDefaults) as? Int, selectedRow <= participants.count {
                pickerView.selectRow(selectedRow, inComponent: 0, animated: true)
            }
            return
        }
        
        // Save current picker view.
        UserDefaults.standard.set(row, forKey: pickerViewRowNSUserDefaults)
        UserDefaults.standard.synchronize()
        
        if row != 0 {
            login(row: row)
        } else {
            logout()
        }
    }
}
