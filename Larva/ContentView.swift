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
            // Check for userId
            if authViewModel.currentUserId != nil {
                if let currentUser = authViewModel.currentUser {
                    AuthenticatedRootView(user: currentUser, sizeClass: horizontalSizeClass)
                        .transition(.opacity)
                } else {
                    // Show a brief loading spinner while fetching the user's stats
                    VStack(spacing: 24) {
                        ProgressView("Loading Profile...")
                            .tint(.mint)
                            .scaleEffect(1.2)
                        
                        // FALLBACK: Escapes the infinite loading trap if the DB fetch fails
                        Button(action: {
                            authViewModel.signOut()
                        }) {
                            Text("Stuck? Force Sign Out")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .transition(.opacity)
                }
            } else {
                // 3. Show Firebase Login/Signup if not authenticated
                LoginView()
                    .transition(.opacity)
            }
        }
        // Smoothly animate the transitions between login, loading, and the main app
        // Updated to watch currentUserId
        .animation(.easeInOut, value: authViewModel.currentUserId)
        .animation(.easeInOut, value: authViewModel.currentUser?.id)
        
        // Inject the auth model so LoginView and SignUpView can use it
        .environmentObject(authViewModel)
    }
}

#Preview {
    ContentView()
}
