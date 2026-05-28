//
//  FriendViewModelTests.swift
//  LarvaTests
//
//  Created by student on 28/05/26.
//

import Testing
@testable import Larva

@Suite("FriendViewModel Local Logic Tests")
@MainActor
struct FriendViewModelTests {

    var viewModel: FriendViewModel
    var mockCurrentUser: User

    init() {
        mockCurrentUser = User(
            id: "USER-1",
            username: "TestPlayer",
            friendCode: "TEST01",
            points: 100,
            currentStreak: 5,
            dailyStepTarget: 5000,
            friendList: [],
            pendingFriendRequests: [],
            unlockedCustomizations: [],
            claimedWaypoints: [:]
        )
        
        viewModel = FriendViewModel(currentUser: mockCurrentUser)
    }

    @Test("Leaderboard correctly sorts users by their streak")
    func leaderboardSortsByStreak() {
        let friendHighStreak = User(id: "USER-2", username: "HighStreak", friendCode: "TEST02", points: 0, currentStreak: 10, dailyStepTarget: 5000, friendList: [], pendingFriendRequests: [], unlockedCustomizations: [], claimedWaypoints: [:])
        
        let friendLowStreak = User(id: "USER-3", username: "LowStreak", friendCode: "TEST03", points: 0, currentStreak: 2, dailyStepTarget: 5000, friendList: [], pendingFriendRequests: [], unlockedCustomizations: [], claimedWaypoints: [:])
        
        viewModel.friends = [friendLowStreak, friendHighStreak]
        
        let leaderboard = viewModel.leaderboard
        
        #expect(leaderboard.count == 3, "Leaderboard should contain the current user and 2 friends")
        #expect(leaderboard[0].username == "HighStreak", "Highest streak should be first")
        #expect(leaderboard[1].username == "TestPlayer", "Current user should be second")
        #expect(leaderboard[2].username == "LowStreak", "Lowest streak should be last")
    }

    @Test("Accepting a friend request updates local arrays")
    func acceptRequestUpdatesLocalState() {
        let pendingUser = User(id: "USER-99", username: "NewFriend", friendCode: "PEND99", points: 0, currentStreak: 0, dailyStepTarget: 5000, friendList: [], pendingFriendRequests: [], unlockedCustomizations: [], claimedWaypoints: [:])
        
        viewModel.currentUser.pendingFriendRequests.append(pendingUser.id)
        viewModel.pendingRequests.append(pendingUser)
        
        viewModel.acceptRequest(from: pendingUser)
        
        #expect(viewModel.currentUser.friendList.contains(pendingUser.id), "Current user's friendList should now contain the new friend's ID")
        #expect(viewModel.friends.contains { $0.id == pendingUser.id }, "ViewModel's friends array should contain the new friend object")
        
        #expect(!viewModel.currentUser.pendingFriendRequests.contains(pendingUser.id), "Pending ID should be removed")
        #expect(!viewModel.pendingRequests.contains { $0.id == pendingUser.id }, "Pending object should be removed")
    }

    @Test("Declining a friend request clears pending requests without adding to friends")
    func declineRequestUpdatesLocalState() {
        let rejectedUser = User(id: "USER-404", username: "RejectedFriend", friendCode: "REJ404", points: 0, currentStreak: 0, dailyStepTarget: 5000, friendList: [], pendingFriendRequests: [], unlockedCustomizations: [], claimedWaypoints: [:])
        
        viewModel.currentUser.pendingFriendRequests.append(rejectedUser.id)
        viewModel.pendingRequests.append(rejectedUser)
        
        viewModel.declineRequest(from: rejectedUser)
        
        #expect(!viewModel.currentUser.friendList.contains(rejectedUser.id), "Rejected user should NOT be in the friendList")
        #expect(!viewModel.friends.contains { $0.id == rejectedUser.id }, "Rejected user should NOT be in the friends array")
        
        #expect(!viewModel.currentUser.pendingFriendRequests.contains(rejectedUser.id), "Pending ID should be removed after decline")
        #expect(!viewModel.pendingRequests.contains { $0.id == rejectedUser.id }, "Pending object should be removed after decline")
    }
}
