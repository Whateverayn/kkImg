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
                    if let thumb = item.thumbnail {
                        Image(nsImage: thumb)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                            .cornerRadius(2)
                    } else {
                        Image(nsImage: NSWorkspace.shared.icon(forFile: item.url.path))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                    }
                    Text(item.url.lastPathComponent)
                }
            }
            
            TableColumn("DateTimeOriginal") {item in
                if item.loadingStatus.isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text(item.exifData?.dateTimeOriginal ?? "Unknown")
                }
            }
            
            TableColumn("GPSPosition") { item in
                if item.loadingStatus.isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text(item.exifData?.gpsPosition ?? "Unknown")
                }
            }
        }
        .tableStyle(.inset)
    }
}

#Preview {
    MainContentView(viewModel: KKViewModel(), mode: .constant(.metadata), view: .constant(.list))
}
