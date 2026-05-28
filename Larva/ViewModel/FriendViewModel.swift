//
//  FriendViewModel.swift
//  Larva
//
//  Created by student on 28/05/26.
//

import Combine
import Foundation

@MainActor
class FriendViewModel: ObservableObject {
    @Published var currentUser: User
    @Published var friends: [User] = []
    @Published var pendingRequests: [User] = []

    // Derived property that automatically sorts friends by their current streak
    var leaderboard: [User] {
        var allUsers = friends
        allUsers.append(currentUser)  // Include the user in their own leaderboard
        return allUsers.sorted { $0.currentStreak > $1.currentStreak }
    }

    init(currentUser: User) {
        self.currentUser = currentUser
        loadDummyData()  // For testing before Firebase
    }

    func sendFriendRequest(to code: String) {
        print("Sending request to friend code: \(code)")
        // Future Firebase logic goes here
    }

    func acceptRequest(from user: User) {
        if !currentUser.friendList.contains(user.id) {
            currentUser.friendList.append(user.id)
            friends.append(user)
        }
        pendingRequests.removeAll { $0.id == user.id }
    }

    func declineRequest(from user: User) {
        pendingRequests.removeAll { $0.id == user.id }
    }

    private func loadDummyData() {
        friends = [
            User(
                id: "ROAM-4F2K",
                username: "Maya Chen",
                points: 1200,
                currentStreak: 5,
                dailyStepTarget: 5000,
                friendList: [],
                pendingFriendRequests: [],
                unlockedCustomizations: []
            ),
            User(
                id: "DASH-9X1P",
                username: "Diego Mar",
                points: 800,
                currentStreak: 3,
                dailyStepTarget: 5000,
                friendList: [],
                pendingFriendRequests: [],
                unlockedCustomizations: []
            ),
        ]

        pendingRequests = [
            User(
                id: "WALK-7B3M",
                username: "Noor R.",
                points: 450,
                currentStreak: 1,
                dailyStepTarget: 5000,
                friendList: [],
                pendingFriendRequests: [],
                unlockedCustomizations: []
            )
        ]
    }
}
