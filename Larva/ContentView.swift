//
//  ContentView.swift
//  Larva
//
//  Created by Elifele Fredrik on 24/05/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage("appearanceTheme") private var appearanceTheme = "System"

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
                if let currentUser = authViewModel.currentUser {
                    AuthenticatedRootView(
                        user: currentUser,
                        sizeClass: horizontalSizeClass
                    )
                    .transition(.opacity)
                } else {
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
