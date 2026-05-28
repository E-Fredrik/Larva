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
    @AppStorage("isDarkMode") private var isDarkMode = true
    
    var body: some View {
        NavigationStack {
            List {
                Section("Appearance") {
                    Picker("Theme", selection: $isDarkMode) {
                        Text("System").tag(false)
                        Text("Dark").tag(true)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Account") {
                    Button(action: {
                        print("Switching account...")
                    }) {
                        Label("Switch Account", systemImage: "person.2.circle.fill")
                            .foregroundColor(.primary)
                    }
                    
                    Button(action: {
                        viewModel.logout()
                        dismiss()
                    }) {
                        Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SettingsView(viewModel: ProfileViewModel(currentUser: User(id: "1", username: "Kenjo", points: 100, currentStreak: 100, friendList: [], pendingFriendRequests: [], unlockedCustomizations: [])))
}
