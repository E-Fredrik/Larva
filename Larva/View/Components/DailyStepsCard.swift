//
//  DailyStepsCard.swift
//  Larva
//
//  Created by Elifele Fredrik on 28/05/26.
//

import SwiftUI

struct DailyStepsCard: View {
    let stepCount: Int
    let targetSteps: Int
    @EnvironmentObject var profileVM: ProfileViewModel
    
    var progress: Double {
        Double(stepCount) / Double(targetSteps)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                ActivityRing(progress: progress, color: profileVM.currentAppTint)
                    .frame(width: 50, height: 50)
                
                Image(systemName: "figure.walk")
                    .foregroundColor(profileVM.currentAppTint)
                    .font(.system(size: 20, weight: .bold))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("DAILY TARGET")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(stepCount)")
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.heavy)
                        .foregroundColor(.primary)
                    
                    Text("/ \(targetSteps)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(20)
    }
}

#Preview {
    DailyStepsCard(stepCount: 4500, targetSteps: 5000)
        .environmentObject(ProfileViewModel(currentUser: User(id: "TEST", username: "TEST", points: 0, currentStreak: 0, friendList: [], pendingFriendRequests: [], unlockedCustomizations: [])))
}
