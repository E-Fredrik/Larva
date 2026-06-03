//
//  LarvaWatchAppApp.swift
//  LarvaWatchApp Watch App
//
//  Created by Elifele Fredrik on 28/05/26.
//

import SwiftUI

/// `LarvaWatchApp_Watch_AppApp` is the top-level entry point for the Apple Watch companion app.
/// It renders a single `WindowGroup` containing `ContentView`, which delegates to `WatchMainView`.
@main
struct LarvaWatchApp_Watch_AppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
