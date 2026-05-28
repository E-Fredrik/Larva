//
//  SettingsView.swift
//  Larva
//
//  Created by student on 28/05/26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ProfileViewModel
    
    @AppStorage("appearanceTheme") private var appearanceTheme = "System"
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
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
                        viewModel.logout()
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
    SettingsView(viewModel: ProfileViewModel(currentUser: User(id: "USER-123", username: "Dave", friendCode: "DAV123", points: 2500, currentStreak: 7, dailyStepTarget: 5000, friendList: [], pendingFriendRequests: [], unlockedCustomizations: [], claimedWaypoints: [:])))
}
