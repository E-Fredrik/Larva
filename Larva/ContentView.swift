//
//  ContentView.swift
//  Larva
//
//  Created by Elifele Fredrik on 24/05/26.
//

import SwiftUI

struct ContentView: View {
    // 1. Initialize your Firebase Auth state manager here
    @StateObject private var authViewModel = AuthViewModel()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        Group {
            if authViewModel.userSession != nil {
                // 2. Wait for the custom User object to be fetched from Firestore
                if let currentUser = authViewModel.currentUser {
                    AuthenticatedRootView(user: currentUser, sizeClass: horizontalSizeClass)
                        .transition(.opacity)
                } else {
                    // Show a brief loading spinner while fetching the user's stats
                    ProgressView("Loading Profile...")
                        .tint(.mint)
                        .transition(.opacity)
                }
            } else {
                // 3. Show Firebase Login/Signup if not authenticated
                LoginView()
                    .transition(.opacity)
            }
        }
        // Smoothly animate the transitions between login, loading, and the main app
        .animation(.easeInOut, value: authViewModel.userSession)
        .animation(.easeInOut, value: authViewModel.currentUser?.id)
        
        // Inject the auth model so LoginView and SignUpView can use it
        .environmentObject(authViewModel)
    }
}

#Preview {
    ContentView()
}
