//
//  QuestViewModel.swift
//  Larva
//
//  Created by student on 28/05/26.
//

import Combine
import FirebaseDatabase
import Foundation

/// Manages the user's daily quest list and automatically awards rewards
/// when a quest's target is reached.
///
/// Currently the quest list is hardcoded (5k and 10k step goals). Progress is
/// driven by a live Firebase listener on `users/<uid>/dailySteps` so the view
/// updates in real time as the user walks.
@MainActor
class QuestViewModel: ObservableObject {
    /// The active set of daily quests shown in `QuestsView`.
    @Published var dailyQuests: [Quest] = []
    /// A copy of the current user profile, used to read streak and sync rewards.
    @Published var currentUser: User

    /// IDs of quests whose rewards have already been claimed in this session.
    /// Prevents the same quest from awarding points more than once.
    @Published var claimedQuestIDs: Set<String> = []
    private let dbRef = Database.database(url: "https://larvva-d2753-default-rtdb.asia-southeast1.firebasedatabase.app").reference()
    init(currentUser: User) {
        self.currentUser = currentUser
        loadDailyQuests()
        listenToDailySteps()
    }

    /// Populates `dailyQuests` with the fixed set of step-based daily goals.
    /// In a future version this could be fetched from Firebase to allow remote configuration.
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
    
    /// Attaches a real-time Firebase listener to the user's `dailySteps` field.
    /// Whenever the step count changes (e.g. synced by `StepTrackerViewModel`),
    /// `updateStepProgress` is called to advance quest progress and trigger auto-claims.
    private func listenToDailySteps() {
        dbRef.child("users").child(currentUser.id).child("dailySteps").observe(.value) { [weak self] snapshot in
            let steps = snapshot.value as? Int ?? 0
            Task { @MainActor in
                self?.updateStepProgress(currentSteps: steps)
            }
        }
    }

    /// Updates each quest's `currentProgress` based on the current step count.
    /// When a step quest is completed for the first time, `autoClaimReward` is triggered.
    /// If `currentSteps` drops to 0 (midnight reset), all progress and claims are cleared.
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

    /// Awards points for the completed quest and increments the streak if all quests are done.
    /// Then persists the updated `currentUser` back to Firebase.
    private func autoClaimReward(for questID: String, at index: Int) {
        claimedQuestIDs.insert(questID)
        currentUser.points += dailyQuests[index].rewardPoints
        
        // If all quests are now claimed, increment the user's streak.
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
