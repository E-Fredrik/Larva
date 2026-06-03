//
//  ContentView.swift
//  LarvaWatchApp Watch App
//
//  Created by Elifele Fredrik on 28/05/26.
//

import SwiftUI

/// The root entry point for the Apple Watch app UI.
///
/// Simply wraps `WatchMainView`, which contains the actual health metric display
/// and workout session controls.
struct ContentView: View {
    var body: some View {
        WatchMainView()
    }
}

#Preview {
    ContentView()
}
