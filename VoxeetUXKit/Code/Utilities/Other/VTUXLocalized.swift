//
//  VTUXLocalized.swift
//  VoxeetUXKit
//
//  Created by Corentin Larroque on 14/08/2019.
//  Copyright © 2019 Voxeet. All rights reserved.
//

class VTUXLocalized {
    static func string(_ key: String) -> String {
        let strLocalBundle = NSLocalizedString(key, bundle: .module, comment: "")
        let strMainBundle = NSLocalizedString(key, comment: "")
        
        return strMainBundle != key ? strMainBundle : strLocalBundle
    }
}
