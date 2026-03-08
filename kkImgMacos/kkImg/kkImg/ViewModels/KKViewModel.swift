//
//  KKViewModel.swift
//  kkImg
//
//  Created by W on R 8/03/03.
//

import Foundation
import AppKit
import QuickLookThumbnailing

import kkImgCore

@Observable
class KKViewModel {
    var items: [ImageItem] = []
    
    private let exifSession = ExifToolSession()
    
    private var analysisQueue: [UUID] = []
    private var isProcessing = false
    
    func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            if provider.canLoadObject(ofClass: URL.self) {
                // 個別に読み込みを開始
                _ = provider.loadObject(ofClass: URL.self) { url, error in
                    if let url = url {
                        DispatchQueue.main.async {
                            // リストに追加
                            let newItem = ImageItem(url: url)
                            self.items.append(newItem)
                            // サムネイル
                            self.generateThumbnail(for: newItem.id)
                            
                            self.enqueueAnalysis(itemid: newItem.id)
                        }
                    }
                }
            }
        }
    }
    
    private func enqueueAnalysis(itemid: UUID) {
        analysisQueue.append(itemid)
        processQueue()
    }
    
    private func processQueue() {
        // すでに実行中, もしくはキューが空なら何もしない
        guard !isProcessing, !analysisQueue.isEmpty else { return }
        
        isProcessing = true
        let nextItemId = analysisQueue.removeFirst()
        
        Task {
            print("Analyzing... \(nextItemId)")
            
            defer {
                Task { @MainActor in
                    print("Analysis done. \(nextItemId)")
                    isProcessing = false
                    processQueue() // 次の項目があれば実行
                }
            }
            
            await performAnalysis(itemid: nextItemId)
        }
    }
    
    private func performAnalysis(itemid: UUID) async {
        guard let index = items.firstIndex(where: { $0.id == itemid }) else { return }
        let url = items[index].url
        // ステータスを解析中にする
        await MainActor.run { items[index].loadingStatus = .loading }
        
        do {
            print("Sending EXIF request for \(url.path)...")
            // -j で全部取得, -n で数値形式
            let result = try await exifSession.execute(args: ["-j", "-n",
                                                              "-DateTimeOriginal", "-CreationDate", "-CreateDate",
                                                              "-GPSLatitude", "-GPSLongitude", "-GPSAltitude", "-GPSCoordinates",
                                                              url.path])
            print("Received EXIF data successfully.")
            if result.succeeded, let data = result.stdout.data(using: .utf8) {
                // json配列としてパース
                if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                   let fullMetadata = jsonArray.first {
                    await MainActor.run {
                        if let idx = self.items.firstIndex(where: { $0.id == itemid }) {
                            print("Updating EXIF data... (ID: \(itemid))")
                            self.items[idx].exifData = KKExifData(rawData: fullMetadata)
                            self.items[idx].loadingStatus = .completed
                        }
                    }
                }
            }
        } catch {
            print("Failed to parse EXIF data: \(error)")
            await MainActor.run {
                if let idx = self.items.firstIndex(where: { $0.id == itemid }) {
                    self.items[idx].loadingStatus = .failed(error.localizedDescription)
                }
            }
        }
    }
    
    func stopSession() async {
        await exifSession.stop()
    }
}

extension KKViewModel {
    func generateThumbnail(for itemid: UUID) {
        guard let index = items.firstIndex(where: { $0.id == itemid }) else { return }
        let url = items[index].url
        
        let size = CGSize(width: 32, height: 32)
        let scale = NSScreen.main?.backingScaleFactor ?? 2.0
        let request = QLThumbnailGenerator.Request(fileAt: url, size: size, scale: scale, representationTypes: .thumbnail)
        
        QLThumbnailGenerator.shared.generateRepresentations(for: request) { (representation, type, error) in
            DispatchQueue.main.async {
                if let thumbnail = representation?.nsImage,
                   let idx = self.items.firstIndex(where: { $0.id == itemid }) {
                    self.items[idx].thumbnail = thumbnail
                }
            }
        }
    }
}
