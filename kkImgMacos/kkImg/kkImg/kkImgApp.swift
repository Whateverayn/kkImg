//
//  kkImgApp.swift
//  kkImg
//
//  Created by W on R 8/02/28.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var viewModel: KKViewModel?
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let viewModel = viewModel else { return .terminateNow }
        
        Task {
            await viewModel.stopSession()
            sender.reply(toApplicationShouldTerminate: true)
        }
        
        return .terminateLater
    }
}

@main
struct kkImgApp: App {
    @State private var viewModel = KKViewModel()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .onAppear {
                    appDelegate.viewModel = viewModel
                }
        }
        .windowToolbarStyle(.unifiedCompact)
    }
}
