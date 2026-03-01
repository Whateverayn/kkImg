//
//  AppViewMode.swift
//  kkImg
//
//  Created by W on R 8/03/02.
//

import Foundation

enum AppViewMode: String, CaseIterable, Identifiable {
    case icons
    case list
    case gallery
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .icons: return "square.grid.2x2"
        case .list: return "list.bullet"
        case .gallery: return "squares.below.rectangle"
        }
    }
    
    var title: String {
        switch self {
        case .icons: return "Icons"
        case .list: return "List"
        case .gallery: return "Gallery"
        }
    }
    
}
