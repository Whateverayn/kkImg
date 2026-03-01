//
//  AppMode.swift
//  kkImg
//
//  Created by W on R 8/03/02.
//

import Foundation

enum AppMode: String, CaseIterable, Identifiable {
    case metadata
    case avif
    case hash
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .metadata: return "rectangle.stack"
        case .avif: return "apple.terminal"
        case .hash: return "number"
        }
    }
    
    var tag: String {
        switch self {
        case .metadata: return "Metadata"
        case .avif: return "AVIF"
        case .hash: return "Hash"
        }
    }
    
}
