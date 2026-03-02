//
//  MainContentView.swift
//  kkImg
//
//  Created by W on R 8/03/02.
//

import SwiftUI
internal import UniformTypeIdentifiers

struct MainContentView: View {
    var viewModel: KKViewModel
    @Binding var mode: AppMode
    @Binding var view: AppViewMode
    
    var body: some View {
        ZStack {
            if viewModel.items.isEmpty {
                emptyStateView
            } else {
                tableView
            }
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            viewModel.handleDrop(providers: providers)
            return true
        }
        .navigationTitle(mode.tag)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "figure.walk.motion")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .foregroundStyle(.secondary)
            VStack(spacing: 8){
                Text("画像をぶち込んで\(mode.tag)を\(view.title)で表示")
                    .font(.headline)
            }
            
            Spacer()
        }
    }
    
    private var tableView: some View {
        Table(viewModel.items) {
            TableColumn("Name") {item in
                HStack {
                    Image(nsImage: NSWorkspace.shared.icon(forFile: item.url.path))
                        .resizable()
                        .frame(width: 16, height: 16)
                    Text(item.url.lastPathComponent)
                }
            }
            
            TableColumn("Format") {item in
                if item.loadingStatus.isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text(item.exifData?.format ?? "Unknown")
                }
            }
            
            TableColumn("Dimensions") { item in
                if item.loadingStatus.isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else if let exif = item.exifData {
                    Text("\(exif.width ?? 0) × \(exif.height ?? 0)")
                } else {
                    Text("Unknown")
                }
            }
        }
        .tableStyle(.inset)
    }
}

#Preview {
    MainContentView(viewModel: KKViewModel(), mode: .constant(.metadata), view: .constant(.list))
}
