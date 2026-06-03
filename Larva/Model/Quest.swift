//
//  QuestModel.swift
//  LarvaLawas
//
//  Created by Eko Nur Cahyo S on 27/05/26.
//

import Foundation

/// Represents a single daily quest the user must complete to earn points and maintain their streak.
/// Quests are displayed in `QuestsView` and their progress is driven by `QuestViewModel`.
struct Quest: Identifiable, Codable {
    /// Unique identifier for the quest (e.g. "q1", "q2").
    var id: String
    /// Human-readable description displayed in the quest list (e.g. "Walk 5,000 steps").
    var title: String
    /// The milestone the user must reach to complete this quest (e.g. 5000 steps).
    var targetGoal: Int
    /// Tracks how far along the user is toward `targetGoal`. Updated live by `QuestViewModel`.
    var currentProgress: Int
    /// Points awarded to the user's total when this quest is auto-claimed upon completion.
    var rewardPoints: Int
    /// Computed completion flag – true once `currentProgress` reaches or exceeds `targetGoal`.
    var isCompleted: Bool {
        currentProgress >= targetGoal
    }
}
