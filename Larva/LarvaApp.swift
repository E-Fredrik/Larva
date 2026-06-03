//
//  LarvaApp.swift
//  Larva
//
//  Created by Elifele Fredrik on 24/05/26.
//

import SwiftUI
import FirebaseCore

/// `AppDelegate` handles the early application lifecycle event needed to configure Firebase
/// before any view is rendered. This must happen before any Firebase service is accessed.
class AppDelegate: NSObject, UIApplicationDelegate {
  /// Called by the system as soon as the app has finished launching.
  /// Firebase is configured here so that Auth, Database, and other services
  /// are ready before the root `ContentView` appears.
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

/// `LarvaApp` is the top-level entry point of the iOS application.
/// It bridges the UIKit `AppDelegate` via `@UIApplicationDelegateAdaptor` so that
/// Firebase can be configured before SwiftUI's lifecycle takes over.
@main
struct LarvaApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

  var body: some Scene {
    WindowGroup {
      ContentView()
            .onAppear {
                // Eagerly instantiate the singleton so the Watch session
                // is activated as early as possible, before any workout begins.
                _ = WatchConnectivityManager.shared
            }
    }
  }
}
