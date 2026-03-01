//
//  DebugUtils.swift
//  kkImg
//
//  Created by W on R 8/03/01.
//

import Foundation
import AppKit

func debugAlert(_ value: Any) {
    let alert = NSAlert()
    alert.messageText = "Debug"
    alert.informativeText = "\(value)"
    alert.runModal()
}
