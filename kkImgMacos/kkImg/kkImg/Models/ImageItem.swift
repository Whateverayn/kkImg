//
//  ImageItem.swift
//  kkImg
//
//  Created by W on R 8/03/03.
//

import Foundation
import AppKit

struct KKExifData {
    var rawData: [String: Any] = [:]
    
    var dateTimeOriginal: String? { rawData["DateTimeOriginal"] as? String }
    var gpsPosition: String? { rawData["GPSPosition"] as? String }
}

enum KKLoadingStatus {
    case pending
    case loading
    case completed
    case failed(String)
    
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}

struct ImageItem: Identifiable {
    var id: UUID = UUID()
    var url: URL
    var exifData: KKExifData?
    var loadingStatus: KKLoadingStatus = .pending
    var thumbnail: NSImage?
}
