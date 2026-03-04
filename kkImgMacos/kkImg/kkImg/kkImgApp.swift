//
//  kkImgApp.swift
//  kkImg
//
//  Created by W on R 8/02/28.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var viewModel: KKViewModel?
    
    func applicationWillTerminate(_ notification: Notification) {
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            await self.viewModel?.stopSession()
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .now() + 5)
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
