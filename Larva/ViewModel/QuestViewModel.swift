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

    @Published var claimedQuestIDs: Set<String> = []
    private let dbRef = Database.database().reference()

    init(currentUser: User) {
        self.currentUser = currentUser
        loadDailyQuests()
        listenToDailySteps()
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
    
    private func listenToDailySteps() {
        dbRef.child("users").child(currentUser.id).child("dailySteps").observe(.value) { [weak self] snapshot in
            let steps = snapshot.value as? Int ?? 0
            Task { @MainActor in
                self?.updateStepProgress(currentSteps: steps)
            }
        }
    }

    func updateStepProgress(currentSteps: Int) {
        if currentSteps == 0 {
            claimedQuestIDs.removeAll()
            for index in dailyQuests.indices {
                dailyQuests[index].currentProgress = 0
            }
            return
        }
        
        for index in dailyQuests.indices {
            let questID = dailyQuests[index].id

            if dailyQuests[index].title.lowercased().contains("steps") {
                if !dailyQuests[index].isCompleted {
                    dailyQuests[index].currentProgress = min(
                        currentSteps,
                        dailyQuests[index].targetGoal
                    )

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
        claimedQuestIDs.insert(questID)
        currentUser.points += dailyQuests[index].rewardPoints
        
        if claimedQuestIDs.count == dailyQuests.count {
            currentUser.currentStreak += 1
        }
        Task {
            do {
                try dbRef.child("users").child(currentUser.id).setValue(
                    from: currentUser
                )
            } catch {
                print("Error syncing quest reward: \(error.localizedDescription)")
            }
        }
    }
}
