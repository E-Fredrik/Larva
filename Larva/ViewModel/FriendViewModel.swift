//
//  FriendViewModel.swift
//  Larva
//
//  Created by student on 28/05/26.
//

import Combine
import Foundation
import FirebaseDatabase

enum LeaderboardMetric: String, CaseIterable {
    case streaks = "Streaks"
    case steps = "Steps"
    case distance = "Distance"
}

enum LeaderboardTimeframe: String, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
}

@MainActor
class FriendViewModel: ObservableObject {
    @Published var currentUser: User
    @Published var friends: [User] = []
    @Published var pendingRequests: [User] = []
    
    @Published var selectedMetric: LeaderboardMetric = .streaks
    @Published var selectedTimeframe: LeaderboardTimeframe = .weekly

    private let dbRef = Database.database().reference()

    var leaderboard: [User] {
        var allUsers = friends
        if !allUsers.contains(where: { $0.id == currentUser.id }) {
            allUsers.append(currentUser)
        }
        
        return allUsers.sorted { userA, userB in
            switch selectedMetric {
            case .streaks:
                return userA.currentStreak > userB.currentStreak
            case .steps:
                return userA.mockSteps(for: selectedTimeframe) > userB.mockSteps(for: selectedTimeframe)
            case .distance:
                return userA.mockDistance(for: selectedTimeframe) > userB.mockDistance(for: selectedTimeframe)
            }
        }
    }

    init(currentUser: User) {
        self.currentUser = currentUser
        Task {
            await fetchFriendsData()
        }
    }
        
    func fetchFriendsData() async {
        do {
            var fetchedFriends: [User] = []
            for friendID in currentUser.friendList {
                let snapshot = try await dbRef.child("users").child(friendID).getData()
                if let friend = try? snapshot.data(as: User.self) {
                    fetchedFriends.append(friend)
                }
            }
            self.friends = fetchedFriends
            
            var fetchedRequests: [User] = []
            for requestID in currentUser.pendingFriendRequests {
                let snapshot = try await dbRef.child("users").child(requestID).getData()
                if let requestUser = try? snapshot.data(as: User.self) {
                    fetchedRequests.append(requestUser)
                }
            }
            self.pendingRequests = fetchedRequests
            
        } catch {
            print("Error fetching friends data: \(error.localizedDescription)")
        }
    }

    func sendFriendRequest(to code: String) {
        guard code != currentUser.friendCode else { return }
        
        Task {
            do {
                let query = dbRef.child("users").queryOrdered(byChild: "friendCode").queryEqual(toValue: code)
                let snapshot = try await query.getData()
                
                guard snapshot.exists(),
                      let children = snapshot.children.allObjects as? [DataSnapshot],
                      let firstChild = children.first,
                      var targetUser = try? firstChild.data(as: User.self) else {
                    print("User with Friend Code \(code) not found.")
                    return
                }
                
                if !targetUser.pendingFriendRequests.contains(currentUser.id) && !targetUser.friendList.contains(currentUser.id) {
                    targetUser.pendingFriendRequests.append(currentUser.id)
                    try dbRef.child("users").child(targetUser.id).setValue(from: targetUser)
                    print("Friend request sent to \(targetUser.username)!")
                }
            } catch {
                print("Error sending request: \(error.localizedDescription)")
            }
        }
    }

    func acceptRequest(from user: User) {
        if !currentUser.friendList.contains(user.id) {
            currentUser.friendList.append(user.id)
            friends.append(user)
        }
        currentUser.pendingFriendRequests.removeAll { $0 == user.id }
        pendingRequests.removeAll { $0.id == user.id }
        
        Task {
            do {
                try dbRef.child("users").child(currentUser.id).setValue(from: currentUser)
                
                var acceptedUser = user
                if !acceptedUser.friendList.contains(currentUser.id) {
                    acceptedUser.friendList.append(currentUser.id)
                    try dbRef.child("users").child(acceptedUser.id).setValue(from: acceptedUser)
                }
                print("Accepted friend request from \(user.username)!")
            } catch {
                print("Error accepting request: \(error.localizedDescription)")
            }
        }
    }

    func declineRequest(from user: User) {
        currentUser.pendingFriendRequests.removeAll { $0 == user.id }
        pendingRequests.removeAll { $0.id == user.id }
        
        Task {
            do {
                try dbRef.child("users").child(currentUser.id).setValue(from: currentUser)
            } catch {
                print("Error declining request: \(error.localizedDescription)")
            }
        }
    }
    
    func removeFriend(_ user: User) {
        currentUser.friendList.removeAll { $0 == user.id }
        friends.removeAll { $0.id == user.id }
        
        Task {
            do {
                try dbRef.child("users").child(currentUser.id).setValue(from: currentUser)
                
                var targetUser = user
                targetUser.friendList.removeAll { $0 == currentUser.id }
                try dbRef.child("users").child(targetUser.id).setValue(from: targetUser)
                
                print("Successfully removed \(user.username) from friends.")
            } catch {
                print("Error removing friend: \(error.localizedDescription)")
            }
        }
    }
}

extension User {
    func mockSteps(for timeframe: LeaderboardTimeframe) -> Int {
        let baseSteps = 3000 + (self.currentStreak * 150) + (self.points % 1000)
        switch timeframe {
        case .daily: return baseSteps
        case .weekly: return baseSteps * 6
        case .monthly: return baseSteps * 24
        }
    }
    
    func mockDistance(for timeframe: LeaderboardTimeframe) -> Double {
        return Double(mockSteps(for: timeframe)) * 0.000762
    }
}
