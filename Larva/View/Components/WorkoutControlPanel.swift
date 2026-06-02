//
//  WorkoutControlPanel.swift
//  Larva
//
//  Created by Elifele Fredrik on 28/05/26.
//

import SwiftUI

struct WorkoutControlPanel: View {
    let isRecording: Bool
    let steps: Int
    let distance: String
    let pace: String
    let onToggleAction: () -> Void
    @EnvironmentObject var profileVM: ProfileViewModel

    var body: some View {
        VStack(spacing: 16) {
            if isRecording {
                HStack(spacing: 32) {
                    WorkoutStats(title: "Steps", value: "\(steps)")
                    WorkoutStats(title: "Distance", value: distance)
                    WorkoutStats(title: "Pace", value: "\(pace)/km")
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Button(action: onToggleAction) {
                HStack {
                    Image(systemName: isRecording ? "stop.fill" : "figure.run")
                    Text(isRecording ? "End Session" : "Start Tracking")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isRecording ? Color.red : profileVM.currentAppTint)
                .foregroundColor(.white)
                .cornerRadius(16)
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.1), radius: 10, y: 5)
    }
}

#Preview {
    WorkoutControlPanel(
        isRecording: true,
        steps: 4500,
        distance: "4km",
        pace: "3:50",
        onToggleAction: {}
    )
    .environmentObject(ProfileViewModel(currentUser: User(id: "TEST", username: "TEST", points: 0, currentStreak: 0, friendList: [], pendingFriendRequests: [], unlockedCustomizations: [])))
}
