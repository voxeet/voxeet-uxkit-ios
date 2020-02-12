//
//  ViewController.swift
//  VoxeetUXKitSample
//
//  Created by Corentin Larroque on 31/03/2017.
//  Copyright © 2017 Voxeet. All rights reserved.
//

import UIKit
import VoxeetSDK
import SDWebImage

class ViewController: UIViewController {
    @IBOutlet weak private var container: UIView!
    @IBOutlet weak private var conferenceNameLabel: UILabel!
    @IBOutlet weak private var conferenceNameTextField: UITextField!
    @IBOutlet weak private var participantsListLabel: UILabel!
    @IBOutlet weak private var participantsPickerView: UIPickerView!
    @IBOutlet weak private var logoutButton: UIButton!
    @IBOutlet weak private var startConferenceButton: UIGradientButton!
    
    private var participants = [VTParticipantInfo]()
    
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
        participants.append(VTParticipantInfo(externalID: nil, name: "None", avatarURL: nil)) // Logout.
        participants.append(VTParticipantInfo(externalID: "111", name: "Benoit", avatarURL: "https://cdn.voxeet.com/images/team-benoit-senard.png"))
        participants.append(VTParticipantInfo(externalID: "222", name: "Stephane", avatarURL: "https://cdn.voxeet.com/images/team-stephane-giraudie.png"))
        participants.append(VTParticipantInfo(externalID: "333", name: "Thomas", avatarURL: "https://cdn.voxeet.com/images/team-thomas.png"))
        participants.append(VTParticipantInfo(externalID: "444", name: "Raphael", avatarURL: "https://cdn.voxeet.com/images/team-raphael.png"))
        participants.append(VTParticipantInfo(externalID: "555", name: "Julie", avatarURL: "https://cdn.voxeet.com/images/team-julie-egglington.png"))
        participants.append(VTParticipantInfo(externalID: "666", name: "Alexis", avatarURL: "https://cdn.voxeet.com/images/team-alexis.png"))
        participants.append(VTParticipantInfo(externalID: "777", name: "Barnabé", avatarURL: "https://cdn.voxeet.com/images/team-barnabe.png"))
        participants.append(VTParticipantInfo(externalID: "888", name: "Corentin", avatarURL: "https://cdn.voxeet.com/images/team-corentin.png"))
        participants.append(VTParticipantInfo(externalID: "999", name: "Romain", avatarURL: "https://cdn.voxeet.com/images/team-romain.png"))
        
        // Saved conference name.
        if let conferenceName = UserDefaults.standard.object(forKey: kConferenceNameNSUserDefaults) as? String {
            conferenceNameTextField.text = conferenceName
        }
        
        // Pre-open a session with the previous participant used.
        if let selectedRow = UserDefaults.standard.object(forKey: kPickerViewRowNSUserDefaults) as? Int, selectedRow <= participants.count && selectedRow != 0 {
            participantsPickerView.selectRow(selectedRow, inComponent: 0, animated: false)
            login(participantInfo: participants[selectedRow])
        }
        
        // Button gradient color.
        let sColor = UIColor(red: 72/255, green: 213/255, blue: 124/255, alpha: 1)
        let eColor = UIColor(red: 192/255, green: 226/255, blue: 73/255, alpha: 1)
        let sPoint = CGPoint(x: 0, y: 1)
        let ePoint = CGPoint(x: 1, y: 0)
        startConferenceButton.gradient(colours: [sColor, eColor], startPoint: sPoint, endPoint: ePoint)
        
        // Container's shadow and corner radius.
        container.layer.cornerRadius = 8
        container.layer.shadowOpacity = 0.1
        container.layer.shadowRadius = 16
        container.layer.shadowOffset = CGSize.zero
        container.layer.shadowPath = UIBezierPath(rect: container.bounds).cgPath
    }
    
    private func login(participantInfo: VTParticipantInfo) {
        participantsPickerView.isUserInteractionEnabled = false
        participantsPickerView.alpha = 0.7
        logoutButton.isEnabled = false
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        // Connect a session with participant information.
        VoxeetSDK.shared.session.open(info: participantInfo) { error in
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
        VoxeetSDK.shared.session.close { error in
            self.participantsPickerView.isUserInteractionEnabled = true
            self.participantsPickerView.alpha = 1
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            
            completion?(error)
        }
    }
    
    @IBAction func logoutAction(_ sender: Any) {
        guard VoxeetSDK.shared.conference.current == nil else { return }
        
        // Reset picker view and logout.
        participantsPickerView.selectRow(0, inComponent: 0, animated: true)
        logout()
    }
    
    @IBAction func startConferenceAction(_ sender: Any) {
        guard let conferenceAlias = conferenceNameTextField.text else {
            print("[VoxeetUXKitSample] \(String(describing: self)).\(#function).\(#line) - Error: Invalid conference ID")
            return
        }
        guard VoxeetSDK.shared.conference.current == nil else { return }
        
        // Save conference name.
        UserDefaults.standard.set(conferenceAlias, forKey: kConferenceNameNSUserDefaults)
        UserDefaults.standard.synchronize()
        
        // Disable startConferenceButton during request network.
        startConferenceButton.isEnabled = false
        
        // Get conference participants without oneself.
        let selectedRow = participantsPickerView.selectedRow(inComponent: 0)
        let participants = self.participants.filter({ $0.externalID != nil && $0.externalID != self.participants[selectedRow].externalID })
        
        // Create a conference (with a custom conference alias).
        let options = VTConferenceOptions()
        options.alias = conferenceAlias
        VoxeetSDK.shared.conference.create(options: options, success: { conference in
            // Join the created conference.
            VoxeetSDK.shared.conference.join(conference: conference, success: { conference in
                // Re-enable startConferenceButton when the request finish.
                self.startConferenceButton.isEnabled = true
            }, fail: { error in
                // Re-enable startConferenceButton when the request finish.
                self.startConferenceButton.isEnabled = true
                self.errorPopUp(error: error)
            })
            
            // Invite other participants if the conference is just created.
            if conference.isNew {
                VoxeetSDK.shared.notification.invite(conference: conference, externalIDs: participants.map({ $0.externalID ?? "" }), completion: nil)
            }
        }, fail: { error in
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
        participantAvatar.sd_setImage(with: URL(string: participants[row].avatarURL ?? ""))
        participantAvatar.layer.cornerRadius = participantAvatar.frame.width / 2
        participantAvatar.layer.masksToBounds = true
        
        // Label name.
        let participantName = UILabel(frame: CGRect(x: participantAvatar.frame.origin.x + participantAvatar.frame.width + 8, y: 0, width: pickerView.frame.width, height: 60))
        participantName.text = participants[row].name
        participantName.font = UIFont.systemFont(ofSize: 14)
        participantName.textColor = UIColor.black
        
        customView.addSubview(participantName)
        customView.addSubview(participantAvatar)
        return customView
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if VoxeetSDK.shared.conference.current != nil {
            if let selectedRow = UserDefaults.standard.object(forKey: kPickerViewRowNSUserDefaults) as? Int, selectedRow <= participants.count {
                pickerView.selectRow(selectedRow, inComponent: 0, animated: true)
            }
            return
        }
        
        if row != 0 {
            logout { error in
                // Save current picker view.
                UserDefaults.standard.set(row, forKey: self.kPickerViewRowNSUserDefaults)
                UserDefaults.standard.synchronize()
                
                self.login(participantInfo: self.participants[row])
            }
        } else {
            logout()
        }
    }
}

class UIGradientButton: UIButton {
    override public class var layerClass: Swift.AnyClass {
        return CAGradientLayer.self
    }
}

extension UIView {
    func gradient(colours: [UIColor], startPoint: CGPoint, endPoint: CGPoint, locations: [NSNumber]? = nil) {
        guard let gradientLayer = self.layer as? CAGradientLayer else { return }
        
        gradientLayer.frame = self.bounds
        gradientLayer.colors = colours.map { $0.cgColor }
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        gradientLayer.locations = locations
    }
}
