//
//  CALayer+Extension.swift
//  VoxeetConferenceKit
//
//  Created by Coco on 15/02/2017.
//  Copyright © 2017 Voxeet. All rights reserved.
//

import Foundation

import UIKit

extension CALayer {
    var shadowUIColor: UIColor? {
        set {
            shadowColor = newValue?.cgColor
        } get {
            return UIColor(cgColor: shadowColor ?? UIColor.clear.cgColor)
        }
    }
    
    var borderUIColor: UIColor? {
        set {
            borderColor = newValue?.cgColor
        } get {
            return UIColor(cgColor: borderColor ?? UIColor.clear.cgColor)
        }
    }
}
