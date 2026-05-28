//
//  QuestViewModelTests.swift
//  LarvaTests
//
//  Created by student on 28/05/26.
//

import Testing

@testable import Larva

@Suite("Quest View Model Tests")
@MainActor
struct QuestViewModelTests {

    var viewModel: QuestViewModel
    var mockUser: User

    init() {
        self.mockUser = User(
            id: "test_user_1",
            username: "TestDave",
            friendCode: "TEST00",
            points: 100,
            currentStreak: 5,
            dailyStepTarget: 5000,
            friendList: [],
            pendingFriendRequests: [],
            unlockedCustomizations: [],
            claimedWaypoints: [:]
        )
        self.viewModel = QuestViewModel(currentUser: mockUser)
    }

    @Test("Dynamic quest generation matches user targets")
    func dynamicQuestGeneration() {
        #expect(
            viewModel.dailyQuests.count == 2,
            "There should be exactly 2 daily quests generated."
        )
        #expect(
            viewModel.dailyQuests[0].targetGoal == 5000,
            "Quest 1 should match the 5000 step target."
        )
        #expect(
            viewModel.dailyQuests[1].targetGoal == 10000,
            "Quest 2 should be double the step target."
        )
    }

    @Test("Partial step progress updates UI but does not award points")
    func partialStepProgress() {
        viewModel.updateStepProgress(currentSteps: 2000)

        #expect(viewModel.dailyQuests[0].currentProgress == 2000)
        #expect(viewModel.dailyQuests[1].currentProgress == 2000)

        #expect(
            !viewModel.dailyQuests[0].isCompleted,
            "Quest 1 should not be completed yet."
        )
        #expect(
            viewModel.currentUser.points == 100,
            "Points should remain at the starting value of 100."
        )
        #expect(
            viewModel.claimedQuestIDs.isEmpty,
            "No quests should be marked as claimed."
        )
    }

    @Test("Completing a single quest awards points but holds streak")
    func singleQuestCompletion() {
        viewModel.updateStepProgress(currentSteps: 5500)

        #expect(
            viewModel.dailyQuests[0].isCompleted,
            "Quest 1 should be completed."
        )
        #expect(
            !viewModel.dailyQuests[1].isCompleted,
            "Quest 2 should NOT be completed."
        )

        #expect(
            viewModel.currentUser.points == 200,
            "User should have 200 points total."
        )
        #expect(
            viewModel.claimedQuestIDs.contains("q1"),
            "Quest 1 should be in the claimed IDs set."
        )

        #expect(
            viewModel.currentUser.currentStreak == 5,
            "Streak should remain at 5 because not all quests are done."
        )
    }

    @Test("Completing all daily quests increases the user's streak")
    func allQuestsCompletion() {
        viewModel.updateStepProgress(currentSteps: 10000)

        #expect(viewModel.dailyQuests[0].isCompleted)
        #expect(viewModel.dailyQuests[1].isCompleted)

        #expect(
            viewModel.currentUser.points == 450,
            "User should have 450 points total."
        )

        #expect(
            viewModel.currentUser.currentStreak == 6,
            "Streak should increase to 6."
        )
        #expect(
            viewModel.claimedQuestIDs.count == 2,
            "Both quests should be in the claimed set."
        )
    }
}
