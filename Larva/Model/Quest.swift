//
//  QuestModel.swift
//  LarvaLawas
//
//  Created by Eko Nur Cahyo S on 27/05/26.
//

import Foundation

struct Quest: Identifiable, Codable {
    var id: String
    var title: String
    var targetGoal: Int
    var currentProgress: Int
    var rewardPoints: Int
    var isCompleted: Bool {
        currentProgress >= targetGoal
    }
}
