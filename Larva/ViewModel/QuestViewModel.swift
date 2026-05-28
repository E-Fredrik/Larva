//
//  QuestViewModel.swift
//  Larva
//
//  Created by student on 28/05/26.
//

import Combine
import FirebaseDatabase
import Foundation

@MainActor
class QuestViewModel: ObservableObject {
    @Published var dailyQuests: [Quest] = []
    @Published var currentUser: User

    // Tracks which quests have already awarded points
    @Published var claimedQuestIDs: Set<String> = []
    private let dbRef = Database.database().reference()

    init(currentUser: User) {
        self.currentUser = currentUser
        loadDailyQuests()
    }

    private func loadDailyQuests() {
        dailyQuests = [
            Quest(
                id: "q1",
                title: "Walk 5,000 steps",
                targetGoal: 5000,
                currentProgress: 0,
                rewardPoints: 100
            ),
            Quest(
                id: "q2",
                title: "Walk 10,000 steps",
                targetGoal: 10000,
                currentProgress: 0,
                rewardPoints: 250
            ),
        ]
    }

    func updateStepProgress(currentSteps: Int) {
        for index in dailyQuests.indices {
            let questID = dailyQuests[index].id

            if dailyQuests[index].title.lowercased().contains("steps") {

                //Updates if it hasn't hit the goal yet
                if !dailyQuests[index].isCompleted {
                    dailyQuests[index].currentProgress = min(
                        currentSteps,
                        dailyQuests[index].targetGoal
                    )

                    //If the update flipped it to completed, and we haven't paid out yet
                    if dailyQuests[index].isCompleted
                        && !claimedQuestIDs.contains(questID)
                    {
                        autoClaimReward(for: questID, at: index)
                    }
                }
            }
        }
    }

    private func autoClaimReward(for questID: String, at index: Int) {
        //Marks as claimed in our Set so it never triggers again
        claimedQuestIDs.insert(questID)

        //Award points directly to the User model
        currentUser.points += dailyQuests[index].rewardPoints
        print(
            "Claimed: \(dailyQuests[index].title)! Awarded \(dailyQuests[index].rewardPoints) pts."
        )

        //If the amount of claimed quests matches the total quests, increase streak
        if claimedQuestIDs.count == dailyQuests.count {
            currentUser.currentStreak += 1
        }
        Task {
            do {
                try dbRef.child("users").child(currentUser.id).setValue(
                    from: currentUser
                )
                print(
                    "Claimed: \(dailyQuests[index].title)! Synced to Firebase."
                )
            } catch {
                print(
                    "Error syncing quest reward: \(error.localizedDescription)"
                )
            }
        }
    }
}
