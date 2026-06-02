//
//  FriendViewModelTests.swift
//  LarvaTests
//
//  Created by student on 28/05/26.
//

import Testing
import Foundation
@testable import Larva

@Suite("Friend ViewModel Tests")
@MainActor
struct FriendViewModelTests {
    
    var viewModel: FriendViewModel!
    var mockCurrentUser: User!
    var friendA: User!
    var pendingFriend: User!

    init() {
        let today = Date()
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: today)!
        let tenDaysAgo = Calendar.current.date(byAdding: .day, value: -10, to: today)!
        
        let historicalActivity: [String: ActivityData] = [
            "today": ActivityData(steps: 2000, caloriesBurned: 100, distanceInMeters: 1500, date: today),
            "three_days": ActivityData(steps: 3000, caloriesBurned: 150, distanceInMeters: 2200, date: threeDaysAgo),
            "ten_days": ActivityData(steps: 5000, caloriesBurned: 250, distanceInMeters: 4000, date: tenDaysAgo)
        ]
        
        mockCurrentUser = User(id: "user_main", username: "MainUser", friendCode: "MAIN01", points: 100, currentStreak: 5, dailyStepTarget: 5000, friendList: ["user_a"], pendingFriendRequests: ["user_pending"], unlockedCustomizations: [], claimedWaypoints: [:], dailyActivity: historicalActivity)
        
        friendA = User(id: "user_a", username: "Friend A", friendCode: "FRND0A", points: 0, currentStreak: 15, dailyStepTarget: 5000, friendList: ["user_main"], pendingFriendRequests: [], unlockedCustomizations: [], claimedWaypoints: [:])
        
        pendingFriend = User(id: "user_pending", username: "Pending User", friendCode: "PEND01", points: 0, currentStreak: 0, dailyStepTarget: 5000, friendList: [], pendingFriendRequests: [], unlockedCustomizations: [], claimedWaypoints: [:])
        
        viewModel = FriendViewModel(currentUser: mockCurrentUser)
        viewModel.friends = [friendA]
        viewModel.pendingRequests = [pendingFriend]
    }

    @Test("Leaderboard sorts by streaks correctly")
    func sortsByStreaks() {
        viewModel.selectedMetric = .streaks
        let leaderboard = viewModel.leaderboard
        
        #expect(leaderboard.count == 2, "Should include current user and 1 friend")
        #expect(leaderboard[0].id == "user_a", "Friend A should be 1st due to highest streak (15 vs 5)")
        #expect(leaderboard[1].id == "user_main", "MainUser should be last")
    }

    @Test("Weekly timeframe math calculates correctly based on history")
    func weeklyStepsCalculation() {
        let weeklySteps = mockCurrentUser.actualSteps(for: .weekly)
        #expect(weeklySteps == 5000, "Weekly steps should sum to 5000 based on history within the last 7 days")
    }
    
    @Test("Monthly timeframe math calculates correctly based on history")
    func monthlyStepsCalculation() {
        let monthlySteps = mockCurrentUser.actualSteps(for: .monthly)
        #expect(monthlySteps == 10000, "Monthly steps should sum to 10000 based on history within the last 30 days")
    }

    @Test("Accepting a friend request instantly updates UI arrays")
    func acceptFriendRequestSync() {
        viewModel.acceptRequest(from: pendingFriend)
        
        #expect(viewModel.pendingRequests.isEmpty, "Pending requests should be cleared instantly")
        #expect(viewModel.friends.contains { $0.id == "user_pending" }, "Pending user should instantly appear in the friends array")
        #expect(viewModel.currentUser.friendList.contains("user_pending"), "Current user's string array should update")
    }
    
    @Test("Declining a friend request instantly updates UI arrays")
    func declineFriendRequestSync() {
        viewModel.declineRequest(from: pendingFriend)
        
        #expect(viewModel.pendingRequests.isEmpty, "Pending requests should be cleared instantly")
        #expect(!viewModel.friends.contains { $0.id == "user_pending" }, "Pending user should NOT be in the friends array")
    }
    
    @Test("Removing a friend updates local arrays instantly")
    func removeFriendUpdatesArrays() {
        viewModel.removeFriend(friendA)
        
        #expect(!viewModel.currentUser.friendList.contains("user_a"), "Friend A's ID should be removed")
        #expect(!viewModel.friends.contains(where: { $0.id == "user_a" }), "Friend A should be removed from friends array")
    }
}
