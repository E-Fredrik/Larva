//
//  ContentView.swift
//  Larva
//
//  Created by Elifele Fredrik on 24/05/26.
//

import SwiftUI

/// `ContentView` is the root view of the application.
/// It acts as an authentication gate — routing users to the correct top-level UI
/// based on whether they are signed in:
///   - Not signed in → `LoginView`
///   - Signed in but profile not yet loaded → loading spinner + force sign-out escape hatch
///   - Signed in with a loaded profile → `AuthenticatedRootView`
struct ContentView: View {
    /// Owns the authentication state machine for the entire session.
    @StateObject private var authViewModel = AuthViewModel()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    /// Persisted preference for the app-wide colour scheme (System / Light / Dark).
    @AppStorage("appearanceTheme") private var appearanceTheme = "System"

    /// Converts the stored string preference into a SwiftUI `ColorScheme`.
    /// Returning `nil` means the system default is used.
    private var activeColorScheme: ColorScheme? {
        switch appearanceTheme {
        case "Light": return .light
        case "Dark": return .dark
        default: return nil
        }
    }

    var body: some View {
        Group {
            if authViewModel.currentUserId != nil {
                // A Firebase UID exists — the user is authenticated.
                if let currentUser = authViewModel.currentUser {
                    // Profile data has been fetched from Realtime Database; show the main app.
                    AuthenticatedRootView(
                        user: currentUser,
                        sizeClass: horizontalSizeClass
                    )
                    .transition(.opacity)
                } else {
                    // UID present but the profile hasn't loaded yet (network latency).
                    // Show a spinner with an escape hatch in case the fetch silently fails.
                    VStack(spacing: 24) {
                        ProgressView("Loading Profile...")
                            .tint(.mint)
                            .scaleEffect(1.2)

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
                // No authenticated user — send them to the login screen.
                LoginView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: authViewModel.currentUserId)
        .animation(.easeInOut, value: authViewModel.currentUser?.id)
        .environmentObject(authViewModel)
        .preferredColorScheme(activeColorScheme)
    }
}

#Preview {
    ContentView()
}
