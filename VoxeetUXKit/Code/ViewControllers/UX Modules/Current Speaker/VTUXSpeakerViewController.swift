//
//  VTUXSpeakerViewController.swift
//  VoxeetUXKit
//
//  Created by Corentin Larroque on 13/06/2019.
//  Copyright © 2019 Voxeet. All rights reserved.
//

import VoxeetSDK
import Kingfisher

@objc public class VTUXSpeakerViewController: UIViewController {
    @IBOutlet weak private var avatar: UIRoundImageView!
    @IBOutlet weak private var name: UILabel!
    
    @objc public func updateSpeaker(user: VTUser) {
        let avatarURL = user.avatarURL ?? ""
        let imageURLStr = avatarURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let imageURL = URL(string: imageURLStr) {
            avatar.kf.setImage(with: imageURL)
        } else {
            avatar.image = UIImage(named: "UserPlaceholder", in: Bundle(for: type(of: self)), compatibleWith: nil)
        }
        name.text = user.name
    }
}
