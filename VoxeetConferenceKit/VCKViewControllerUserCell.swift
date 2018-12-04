//
//  VCKViewControllerUserCell.swift
//  VoxeetConferenceKit
//
//  Created by Coco on 16/02/2017.
//  Copyright © 2017 Voxeet. All rights reserved.
//

import UIKit
import VoxeetSDK

class VCKViewControllerUserCell: UICollectionViewCell {
    @IBOutlet weak var videoRenderer: VTVideoView!
    @IBOutlet weak var avatar: UIImageView!
    @IBOutlet weak var name: UILabel!
    
    var user: VTUser?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        videoRenderer.isHidden = true
        
        // Unattach the old stream before reusing the cell.
        if let userID = user?.id, let stream = VoxeetSDK.shared.conference.mediaStream(userID: userID), !stream.videoTracks.isEmpty {
            VoxeetSDK.shared.conference.unattachMediaStream(stream, renderer: videoRenderer)
        }
    }
}
