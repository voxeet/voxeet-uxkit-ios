//
//  UIRoundImageView.swift
//  VoxeetUXKit
//
//  Created by Corentin Larroque on 23/07/2019.
//  Copyright © 2019 Voxeet. All rights reserved.
//

class UIRoundImageView: UIImageView {
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.width / 2
    }
}
