//
//  UIApplicationExtension.swift
//  VoxeetUXKit
//
//  Created by Yuriy Ganushevich on 20/01/2022.
//  Copyright © 2022 Voxeet. All rights reserved.
//

import Foundation

extension UIApplication {

    static var keyWindow: UIWindow? {
        if #available(iOS 13, *) {
            return UIApplication
                .shared
                .connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
        } else {
            return UIApplication
                .shared
                .windows
                .first { $0.isKeyWindow }
        }
    }
}
