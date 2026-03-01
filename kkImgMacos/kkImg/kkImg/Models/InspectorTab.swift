//
//  InspectorTab.swift
//  kkImg
//
//  Created by W on R 8/03/01.
//

import SwiftUI

enum InspectorTab: String, CaseIterable, Identifiable{
    case file
    case filters
    case actions
    case activity
    
    var id: String {
        rawValue
    }
    
    var iconName: String {
        switch self {
        case .file: return "document"
        case .filters: return "line.3.horizontal.decrease.circle"
        case .actions: return "play.circle"
        case .activity: return "figure.dance.circle"
        }
    }
    
    var displayName: String {
        switch self {
        case .file: return "File"
        case .filters: return "Filters"
        case .actions: return "Actions"
        case .activity: return "Activity"
        }
    }
}
