//
//  KKViewModel.swift
//  kkImg
//
//  Created by W on R 8/03/03.
//

import Foundation

@Observable
class KKViewModel {
    var items: [ImageItem] = []
    
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
                            
                            // 解析開始
                            self.startAnalyzing(itemid: newItem.id)
                        }
                    }
                }
            }
        }
    }
    
    private func startAnalyzing(itemid: UUID) {
        guard let index = items.firstIndex(where: { $0.id == itemid }) else { return }
        
        // ステータスを解析中にする
        items[index].loadingStatus = .loading
        
        Task {
            try? await Task.sleep(for: .seconds(Double.random(in: 0.5...2.0)))
            
            await MainActor.run {
                if let idx = self.items.firstIndex(where: { $0.id == itemid }) {
                    // 解析結果を埋めて完了にする
                    self.items[idx].exifData = KKExifData(
                        width: Int.random(in: 100...1000),
                        height: Int.random(in: 100...1000),
                        format: self.items[idx].url.pathExtension.uppercased(),
                    )
                    self.items[idx].loadingStatus = .completed
                }
            }
        }
    }
}
