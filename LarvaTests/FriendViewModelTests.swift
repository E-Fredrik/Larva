//
//  FriendViewModelTests.swift
//  LarvaTests
//
//  Created by student on 28/05/26.
//

import Testing
@testable import Larva

@Suite("Friend ViewModel Tests")
@MainActor
struct FriendViewModelTests {
    
    var viewModel: FriendViewModel!
    var mockCurrentUser: User!
    var friendA: User!
    var friendB: User!


    init() {
        mockCurrentUser = User(id: "user_main", username: "MainUser", friendCode: "MAIN01", points: 100, currentStreak: 5, dailyStepTarget: 5000, friendList: ["user_a", "user_b"], pendingFriendRequests: [], unlockedCustomizations: [], claimedWaypoints: [:])
        
        friendA = User(id: "user_a", username: "Friend A", friendCode: "FRND0A", points: 0, currentStreak: 15, dailyStepTarget: 5000, friendList: ["user_main"], pendingFriendRequests: [], unlockedCustomizations: [], claimedWaypoints: [:])
        
        friendB = User(id: "user_b", username: "Friend B", friendCode: "FRND0B", points: 900, currentStreak: 10, dailyStepTarget: 5000, friendList: ["user_main"], pendingFriendRequests: [], unlockedCustomizations: [], claimedWaypoints: [:])
        
        viewModel = FriendViewModel(currentUser: mockCurrentUser)
        viewModel.friends = [friendA, friendB]
    }

    @Test("Leaderboard sorts by streaks correctly")
    func sortsByStreaks() {
        viewModel.selectedMetric = .streaks
        let leaderboard = viewModel.leaderboard
        
        #expect(leaderboard.count == 3, "Should include current user and 2 friends")
        #expect(leaderboard[0].id == "user_a", "Friend A should be 1st due to highest streak")
        #expect(leaderboard[1].id == "user_b", "Friend B should be 2nd")
        #expect(leaderboard[2].id == "user_main", "MainUser should be last")
    }

    @Test("Leaderboard sorts by steps correctly")
    func sortsBySteps() {
        viewModel.selectedMetric = .steps
        let leaderboard = viewModel.leaderboard
        
        #expect(leaderboard[0].id == "user_b", "Friend B should be 1st due to high points calculation")
        #expect(leaderboard[1].id == "user_a", "Friend A should be 2nd")
        #expect(leaderboard[2].id == "user_main", "MainUser should be 3rd")
    }

    @Test("Timeframe multiplier scales steps correctly")
    func timeframeMultiplier() {
        viewModel.selectedMetric = .steps
        viewModel.selectedTimeframe = .weekly
        
        let weeklyStepsUserB = viewModel.leaderboard.first(where: { $0.id == "user_b" })?.mockSteps(for: .weekly) ?? 0
        let dailyStepsUserB = friendB.mockSteps(for: .daily)
        
        #expect(weeklyStepsUserB == dailyStepsUserB * 6, "Weekly timeframe should correctly multiply the base steps")
    }
    
    @Test("Removing a friend updates local arrays")
    func removeFriendUpdatesArrays() {
        viewModel.removeFriend(friendA)
        
        #expect(!viewModel.currentUser.friendList.contains("user_a"), "Friend A's ID should be removed")
        #expect(!viewModel.friends.contains(where: { $0.id == "user_a" }), "Friend A should be removed from friends array")
        #expect(viewModel.currentUser.friendList.contains("user_b"), "Friend B should remain untouched")
    }
}
