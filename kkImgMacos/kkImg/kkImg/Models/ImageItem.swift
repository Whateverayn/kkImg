//
//  ImageItem.swift
//  kkImg
//
//  Created by W on R 8/03/03.
//

import Foundation

struct KKExifData {
    var width: Int?
    var height: Int?
    var format: String?
    var aperture: Double?
    var shutterSpeed: Double?
    var iso: Int?
    var make: String?
    var model: String?
    var flash: String?
    var exposureMode: String?
    var whiteBalance: String?
    var exposureProgram: String?
    var lensModel: String?
    var dateTimeOriginal: Date?
    var copyright: String?
    var location: String?
    var lensSpecification: String?
    var sceneType: String?
    var sceneCaptureType: String?
    var lensSpecificationInfo: String?
    var lensMake: String?
    var lensModelInfo: String?
    var lensSpecificationVersion: String?
    var lensMakeVersion: String?
    var lensSerialNumber: String?
    var lensVersion: String?
    var lensSpecificationSerialNumber: String?
    var lensMakeSerialNumber: String?
    var lensVersionSerialNumber: String?
    var lensMakeVersionSerialNumber: String?
    var lensSerialNumberSerialNumber: String?
    var lensVersionSerialNumberSerialNumber: String?
    var lensMakeVersionSerialNumberSerialNumber: String?
    var lensSpecificationSerialNumberSerialNumber: String?
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
}
