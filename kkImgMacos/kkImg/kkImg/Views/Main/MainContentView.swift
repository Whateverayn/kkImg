//
//  MainContentView.swift
//  kkImg
//
//  Created by W on R 8/03/02.
//

import SwiftUI
internal import UniformTypeIdentifiers

struct MainContentView: View {
    @Binding var mode: AppMode
    @Binding var view: AppViewMode
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "figure.walk.motion")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .foregroundStyle(.secondary)
            VStack(spacing: 8){
                Text("画像をぶち込んで" + mode.tag + "を" + view.title + "で表示")
                    .font(.headline)
            }
            Spacer()
        }
        .onDrop(of: [.image], isTargeted: nil) { providers in
            
            return true
        }
        .navigationTitle(mode.tag)
    }
}

#Preview {
    MainContentView(mode: .constant(.metadata), view: .constant(.list))
}
