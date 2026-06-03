//
//  SettingsView.swift
//  Larva
//
//  Created by student on 28/05/26.
//

import SwiftUI

/// A settings sheet accessible from `ProfileView` for app-level preferences.
///
/// Most settings here (`appearanceTheme`, `notificationsEnabled`, `privacySetting`) are
/// persisted locally via `@AppStorage` and are not synced to Firebase — they control
/// the local device experience only.
///
/// The **Log Out** action calls `AuthViewModel.signOut()` and dismisses the sheet,
/// which causes `ContentView` to observe the auth state change and show `LoginView`.
struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    /// The profile view model is observed here to allow future Firebase-backed settings.
    @ObservedObject var viewModel: ProfileViewModel
    
    @EnvironmentObject var authViewModel: AuthViewModel

    /// Controls the system colour scheme override (System/Light/Dark). Stored in `UserDefaults`.
    @AppStorage("appearanceTheme") private var appearanceTheme = "System"
    /// Whether the app will attempt to schedule local notifications.
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    /// Who can see the user's stats on the leaderboard (UI only, not yet enforced in rules).
    @AppStorage("privacySetting") private var privacySetting = "Friends Only"

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Appearance")) {
                    Picker("Theme", selection: $appearanceTheme) {
                        Text("System").tag("System")
                        Text("Light").tag("Light")
                        Text("Dark").tag("Dark")
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 4)
                }

                Section(header: Text("Account Setting")) {
                    Toggle("Notifications", isOn: $notificationsEnabled)
                        .tint(.mint)

                    Picker("Privacy", selection: $privacySetting) {
                        Text("Everyone").tag("Everyone")
                        Text("Friends Only").tag("Friends Only")
                        Text("No One").tag("No One")
                    }

                    Button(action: {
                        print("Opening Help & Support...")
                    }) {
                        HStack {
                            Text("Help & Support")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section {
                    Button(action: {
                        authViewModel.signOut()
                        dismiss()
                    }) {
                        Text("Log Out")
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.title3)
                    }
                }
            }
        }
        .presentationDetents([.fraction(0.65)])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    SettingsView(
        viewModel: ProfileViewModel(
            currentUser: User(
                id: "USER-123",
                username: "Dave",
                friendCode: "DAV123",
                points: 2500,
                currentStreak: 7,
                dailyStepTarget: 5000,
                friendList: [],
                pendingFriendRequests: [],
                unlockedCustomizations: [],
                claimedWaypoints: [:]
            )
        )
    )
    .environmentObject(AuthViewModel()) 
}
