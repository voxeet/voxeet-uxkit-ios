//
//  Print+Extension.swift
//  VoxeetConferenceKit
//
//  Created by Coco on 03/07/2017.
//  Copyright © 2017 Voxeet. All rights reserved.
//

import Foundation

func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    #if DEBUG
        Swift.print(items[0], separator: separator, terminator: terminator)
    #endif
}
