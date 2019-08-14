//
//  UIButton+Extension.swift
//  VoxeetUXKit
//
//  Created by Corentin Larroque on 02/08/2019.
//  Copyright © 2019 Voxeet. All rights reserved.
//

extension UIButton {
    func isEnabled(_ isEnabled: Bool, animated: Bool) {
        UIView.transition(with: self,
                          duration: 0.125,
                          options: .transitionCrossDissolve,
                          animations: { self.isEnabled = isEnabled },
                          completion: nil)
    }
}
