//
//  MPVolumeView+Extension.swift
//  VoxeetConferenceKit
//
//  Created by Corentin Larroque on 4/8/19.
//  Copyright © 2019 Voxeet. All rights reserved.
//

import MediaPlayer

extension MPVolumeView {
    static func setVolume(_ volume: Float) {
        let volumeView = MPVolumeView()
        let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            slider?.value = volume
        }
    }
}
