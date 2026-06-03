//
//  FriendViewModel.swift
//  Larva
//
//  Created by student on 28/05/26.
//

//
//  FriendViewModel.swift
//  Larva
//

import Combine
import Foundation
import FirebaseDatabase

enum LeaderboardMetric: String, CaseIterable {
    case streaks = "Streaks"; case steps = "Steps"; case distance = "Distance"
}

enum LeaderboardTimeframe: String, CaseIterable {
    case daily = "Daily"; case weekly = "Weekly"; case monthly = "Monthly"
}

@MainActor
class FriendViewModel: ObservableObject {
    @Published var currentUser: User
    @Published var friends: [User] = []
    @Published var pendingRequests: [User] = []
    
    @Published var selectedMetric: LeaderboardMetric = .streaks
    @Published var selectedTimeframe: LeaderboardTimeframe = .weekly
    
    // UI Feedback
    @Published var alertMessage: String = ""
    @Published var showAlert: Bool = false

    private let dbRef = Database.database().reference()

    var leaderboard: [User] {
        var allUsers = friends
        if !allUsers.contains(where: { $0.id == currentUser.id }) { allUsers.append(currentUser) }
        return allUsers.sorted { userA, userB in
            switch selectedMetric {
            case .streaks: return userA.currentStreak > userB.currentStreak
            case .steps: return userA.actualSteps(for: selectedTimeframe) > userB.actualSteps(for: selectedTimeframe)
            case .distance: return userA.actualDistance(for: selectedTimeframe) > userB.actualDistance(for: selectedTimeframe)
            }
        }
    }

    init(currentUser: User) {
        self.currentUser = currentUser
        listenForFriendUpdates()
    }
    
    private func listenForFriendUpdates() {
        dbRef.child("users").child(currentUser.id).observe(.value) { [weak self] snapshot in
            guard let self = self, let dict = snapshot.value as? [String: Any] else { return }
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: dict),
               let updatedUser = try? JSONDecoder().decode(User.self, from: jsonData) {
                self.currentUser = updatedUser
                Task { await self.fetchDetailedUsers(friendIds: updatedUser.friendList, requestIds: updatedUser.pendingFriendRequests) }
            }
        }
    }
    
    private func fetchDetailedUsers(friendIds: [String], requestIds: [String]) async {
        var fetchedFriends: [User] = []; var fetchedRequests: [User] = []
        for fid in friendIds {
            if let snap = try? await dbRef.child("users").child(fid).getData(), let data = snap.value as? [String: Any], let jsonData = try? JSONSerialization.data(withJSONObject: data), let u = try? JSONDecoder().decode(User.self, from: jsonData) { fetchedFriends.append(u) }
        }
        for rid in requestIds {
            if let snap = try? await dbRef.child("users").child(rid).getData(), let data = snap.value as? [String: Any], let jsonData = try? JSONSerialization.data(withJSONObject: data), let u = try? JSONDecoder().decode(User.self, from: jsonData) { fetchedRequests.append(u) }
        }
        self.friends = fetchedFriends
        self.pendingRequests = fetchedRequests
    }

    func sendFriendRequest(to code: String) async {
        let cleanCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanCode != currentUser.friendCode else {
            self.alertMessage = "You cannot add yourself!"; self.showAlert = true; return
        }
        
        do {
            let query = dbRef.child("users").queryOrdered(byChild: "friendCode").queryEqual(toValue: cleanCode)
            let snapshot = try await query.getData()
            guard snapshot.exists(), let first = snapshot.children.allObjects.first as? DataSnapshot, let dict = first.value as? [String: Any], let jsonData = try? JSONSerialization.data(withJSONObject: dict), var targetUser = try? JSONDecoder().decode(User.self, from: jsonData) else {
                self.alertMessage = "User not found."; self.showAlert = true; return
            }
            
            if targetUser.friendList.contains(currentUser.id) { self.alertMessage = "Already friends." }
            else if targetUser.pendingFriendRequests.contains(currentUser.id) { self.alertMessage = "Request already sent." }
            else {
                targetUser.pendingFriendRequests.append(currentUser.id)
                try await dbRef.child("users").child(targetUser.id).child("pendingFriendRequests").setValue(targetUser.pendingFriendRequests)
                self.alertMessage = "Request sent to \(targetUser.username)!"
            }
        } catch { self.alertMessage = "Error sending request." }
        self.showAlert = true
    }

    func acceptRequest(from user: User) {
        // 1. Optimistic UI Update (Triggers an instant SwiftUI redraw)
        if !currentUser.friendList.contains(user.id) {
            currentUser.friendList.append(user.id)
            friends.append(user)
        }
        currentUser.pendingFriendRequests.removeAll { $0 == user.id }
        pendingRequests.removeAll { $0.id == user.id }
        
        // 2. Background Firebase Update
        Task {
            do {
                try await dbRef.child("users").child(currentUser.id).child("friendList").setValue(currentUser.friendList)
                try await dbRef.child("users").child(currentUser.id).child("pendingFriendRequests").setValue(currentUser.pendingFriendRequests)
                
                var targetFriendList = user.friendList
                if !targetFriendList.contains(currentUser.id) {
                    targetFriendList.append(currentUser.id)
                    try await dbRef.child("users").child(user.id).child("friendList").setValue(targetFriendList)
                }
            } catch {
                print("Error accepting request")
            }
        }
    }

    func declineRequest(from user: User) {
        // 1. Optimistic UI Update (Triggers an instant SwiftUI redraw)
        currentUser.pendingFriendRequests.removeAll { $0 == user.id }
        pendingRequests.removeAll { $0.id == user.id }
        
        // 2. Background Firebase Update
        Task {
            do {
                try await dbRef.child("users").child(currentUser.id).child("pendingFriendRequests").setValue(currentUser.pendingFriendRequests)
            } catch {
                print("Error declining request")
            }
        }
    }
    
    func removeFriend(_ user: User) {
        // 1. Optimistic UI Update
        currentUser.friendList.removeAll { $0 == user.id }
        friends.removeAll { $0.id == user.id }
        
        // 2. Background Firebase Update
        Task {
            do {
                try await dbRef.child("users").child(currentUser.id).child("friendList").setValue(currentUser.friendList)
                
                var targetFriendList = user.friendList
                targetFriendList.removeAll { $0 == currentUser.id }
                try await dbRef.child("users").child(user.id).child("friendList").setValue(targetFriendList)
            } catch {
                print("Error removing friend")
            }
        }
    }
}

extension User {
    func actualSteps(for timeframe: LeaderboardTimeframe) -> Int {
        switch timeframe {
        case .daily: return self.dailySteps
        case .weekly: return self.dailySteps + (self.currentStreak * 1000)
        case .monthly: return self.dailySteps + (self.currentStreak * 5000)
        }
    }
    func actualDistance(for timeframe: LeaderboardTimeframe) -> Double { return Double(actualSteps(for: timeframe)) * 0.000762 }
}
