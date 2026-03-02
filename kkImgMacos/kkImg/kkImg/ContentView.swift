//
//  ContentView.swift
//  kkImg
//
//  Created by W on R 8/02/28.
//

import SwiftUI
internal import UniformTypeIdentifiers

struct ContentView: View {
    @State private var selectedTab: AppMode = .metadata
    @State private var viewMode: AppViewMode = .list
    @State private var inspectorTab: InspectorTab = .file
    @State private var isInspectorPresented: Bool = true
    @State private var columnVisibility = NavigationSplitViewVisibility.detailOnly
    
    var body: some View {
        NavigationStack {
            MainContentView(viewModel: KKViewModel(), mode: $selectedTab, view: $viewMode)
        }
        .toolbar {
            MainToolbar(mode: $selectedTab, view: $viewMode)
        }
        .inspector(isPresented: $isInspectorPresented) {
            InspectorMainView(selection: $inspectorTab, isPresented: $isInspectorPresented)
        }
    }
}

#Preview {
    ContentView()
}
