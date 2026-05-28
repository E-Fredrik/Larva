//
//  QuestViewModelTests.swift
//  LarvaTests
//
//  Created by student on 28/05/26.
//

import Testing
@testable import Larva

@Suite("Quest ViewModel Tests")
@MainActor
struct QuestViewModelTests {

    var viewModel: QuestViewModel!
    var mockUser: User!

    init() {
        mockUser = User(id: "test_user_1", username: "TestDave", friendCode: "TEST00", points: 100, currentStreak: 5, dailyStepTarget: 5000, friendList: [], pendingFriendRequests: [], unlockedCustomizations: [], claimedWaypoints: [:])
        viewModel = QuestViewModel(currentUser: mockUser)
    }

    @Test("Dynamic quest generation matches user target")
    func dynamicQuestGeneration() {
        #expect(viewModel.dailyQuests.count == 2)
        #expect(viewModel.dailyQuests[0].targetGoal == 5000)
        #expect(viewModel.dailyQuests[1].targetGoal == 10000)
    }

    @Test("Partial step progress does not award points")
    func partialStepProgress() {
        viewModel.updateStepProgress(currentSteps: 2000)
        
        #expect(viewModel.dailyQuests[0].currentProgress == 2000)
        #expect(viewModel.dailyQuests[1].currentProgress == 2000)
        #expect(viewModel.dailyQuests[0].isCompleted == false)
        #expect(viewModel.currentUser.points == 100)
        #expect(viewModel.claimedQuestIDs.isEmpty)
    }

    @Test("Single quest completion awards points")
    func singleQuestCompletion() {
        viewModel.updateStepProgress(currentSteps: 5500)
        
        #expect(viewModel.dailyQuests[0].isCompleted == true)
        #expect(viewModel.dailyQuests[1].isCompleted == false)
        
        #expect(viewModel.currentUser.points == 200)
        #expect(viewModel.claimedQuestIDs.contains("q1"))
        #expect(viewModel.currentUser.currentStreak == 5, "Streak should not increase until all quests are done")
    }

    @Test("Completing all quests increases the daily streak")
    func allQuestsCompletion() {
        viewModel.updateStepProgress(currentSteps: 10000)
        
        #expect(viewModel.dailyQuests[0].isCompleted == true)
        #expect(viewModel.dailyQuests[1].isCompleted == true)
        
        #expect(viewModel.currentUser.points == 450)
        #expect(viewModel.currentUser.currentStreak == 6, "Streak should increase to 6")
        #expect(viewModel.claimedQuestIDs.count == 2)
    }
}
