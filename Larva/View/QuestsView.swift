//
//  QuestsView.swift
//  Larva
//
//  Created by student on 28/05/26.
//

import SwiftUI

struct QuestsView: View {
    @ObservedObject var viewModel: QuestViewModel

    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                ZStack {
                    ScrollView {
                        VStack(spacing: 24) {
                            VStack(spacing: 8) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.orange)
                                    .shadow(
                                        color: .orange.opacity(0.5),
                                        radius: 10,
                                        x: 0,
                                        y: 5
                                    )

                                Text(
                                    "\(viewModel.currentUser.currentStreak) Day Streak"
                                )
                                .font(.title)
                                .fontWeight(.bold)

                                Text(
                                    "Complete all daily quests to keep it burning!"
                                )
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            }
                            .padding(.top, 20)
                            .padding(.bottom, 10)

                            VStack(spacing: 16) {
                                ForEach(viewModel.dailyQuests) { quest in
                                    QuestRow(quest: quest)
                                }
                            }
                            .padding(.horizontal)

                            Spacer().frame(height: 100)
                        }
                    }

                    VStack {
                        Spacer()
                        Text(
                            "Solo quests are automatically completed and rewarded as you track your steps."
                        )
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.thinMaterial)
                        .cornerRadius(16)
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
                .navigationTitle("Daily Quests")
            }
        } else {
            // Fallback on earlier versions
        }
    }
}

#Preview {
    QuestsView(
        viewModel: QuestViewModel(
            currentUser: User(
                id: "1",
                username: "Kenjo",
                points: 2500,
                currentStreak: 100,
                dailyStepTarget: 5000,
                friendList: [],
                pendingFriendRequests: [],
                unlockedCustomizations: []
            )
        )
    )
}
