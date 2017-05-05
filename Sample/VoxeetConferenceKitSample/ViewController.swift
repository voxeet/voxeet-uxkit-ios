//
//  ViewController.swift
//  VoxeetConferenceKitSample
//
//  Created by Coco on 31/03/2017.
//  Copyright © 2017 Corentin Larroque. All rights reserved.
//

import UIKit
import VoxeetConferenceKit

class ViewController: UIViewController {
    @IBOutlet weak var conferenceIDTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Logs your user to Voxeet in order to receive VoIP push notifications or any Voxeet notifications before starting a conference.
        let ownParticipant = VoxeetParticipant(id: "1111", name: "John Smith", avatarURL: URL(string: "https://docs.moodle.org/27/en/images_en/7/7c/F1.png"))
        VoxeetConferenceKit.shared.openSession(participant: ownParticipant)
    }
    
    @IBAction func joinConferenceAction(_ sender: Any) {
        guard let conferenceID = conferenceIDTextField.text else {
            print("[VoxeetConferenceKitSample] \(#function).\(#line) Error: Invalid conference ID.")
            return
        }
        
        // Set up participants.
        let participant1 = VoxeetParticipant(id: "2222", name: "Bob", avatarURL: URL(string: "https://docs.moodle.org/27/en/images_en/7/7c/F1.png"))
        let participant2 = VoxeetParticipant(id: "3333", name: "Matt", avatarURL: URL(string: "https://docs.moodle.org/27/en/images_en/7/7c/F1.png"))
        
        // Initialize conference.
        VoxeetConferenceKit.shared.initializeConference(id: conferenceID, participants: [participant1, participant2])
        
        // Start and join conference.
        VoxeetConferenceKit.shared.startConference(sendInvitation: true, success: { (confID) in
            // Debug.
            print("[VoxeetConferenceKitSample] \(#function).\(#line) Conference successfully started: \(confID)")
        }, fail: { (error) in
            // Debug.
            print("[VoxeetConferenceKitSample] \(#function).\(#line) Error: \(error)")
            
            // Error message.
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Error", message: "Something went wrong with the conference.", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        })
    }
}
