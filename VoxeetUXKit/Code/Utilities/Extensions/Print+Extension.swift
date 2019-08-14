//
//  Print+Extension.swift
//  VoxeetUXKit
//
//  Created by Corentin Larroque on 03/07/2017.
//  Copyright © 2017 Voxeet. All rights reserved.
//

func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    #if DEBUG
        Swift.print(items[0], separator: separator, terminator: terminator)
    #endif
}
