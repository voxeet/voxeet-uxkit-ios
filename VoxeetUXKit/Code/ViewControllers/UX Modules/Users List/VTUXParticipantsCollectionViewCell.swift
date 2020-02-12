//
//  VTUXParticipantCollectionViewCell.swift
//  VoxeetUXKit
//
//  Created by Corentin Larroque on 18/06/2019.
//  Copyright © 2019 Voxeet. All rights reserved.
//

import VoxeetSDK

class VTUXParticipantCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var videoRenderer: VTVideoView!
    @IBOutlet weak var avatar: UIRoundImageView!
    @IBOutlet weak var name: UILabel!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Default visible elements.
        avatar.isHidden = false
        avatar.layer.borderWidth = 0
        videoRenderer.isHidden = true
        videoRenderer.layer.borderWidth = 0
        
        // Unattach the old stream before reusing the cell.
        videoRenderer.unattach()
    }
}
