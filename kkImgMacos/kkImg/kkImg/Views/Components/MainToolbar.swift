//
//  MainToolbar.swift
//  kkImg
//
//  Created by W on R 8/03/02.
//

import SwiftUI

struct MainToolbar: ToolbarContent {
    @Binding var mode: AppMode
    @Binding var view: AppViewMode
    
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            Picker("Mode", selection: $mode) {
                ForEach(AppMode.allCases) { mode in
                    Label(mode.tag, systemImage: mode.icon).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .help("Switch between modes")
        }
        
        ToolbarItem(placement: .principal) {
            Picker("View Mode", selection: $view) {
                ForEach(AppViewMode.allCases) { mode in
                    Label(mode.title, systemImage: mode.icon).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .help("Change the view style")
        }
        
        ToolbarItemGroup(placement: .secondaryAction) {
            ControlGroup{
                Button {
                    debugAlert("Importing...")
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                }
                .help("Import files")
                
                Button {
                    debugAlert("Exporting...")
                } label: {
                    Label("Export", systemImage: "folder")
                }
                .help("Export files")
                
                Button {
                    debugAlert("Showing in Finder...")
                } label: {
                    Label("Show in Finder", systemImage: "arrow.up.forward.app")
                }
                .help("Reveal selected item in Finder")
            }
        }
    }
}

#Preview {
    NavigationStack{
        Text("Hello, World!")
            .toolbar{
                MainToolbar(
                    mode: .constant(.metadata), view: .constant(.list)
                )
            }
    }
}
