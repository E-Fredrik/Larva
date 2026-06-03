//
//  FriendViewModel.swift
//  Larva
//
//  Created by student on 28/05/26.
//

import Combine
import Foundation
import FirebaseDatabase

/// Metrics available for comparing users on the leaderboard.
enum LeaderboardMetric: String, CaseIterable {
    case streaks = "Streaks"; case steps = "Steps"; case distance = "Distance"
}

/// Time windows used to filter leaderboard step/distance scores.
enum LeaderboardTimeframe: String, CaseIterable {
    case daily = "Daily"; case weekly = "Weekly"; case monthly = "Monthly"
}

/// Manages the user's social graph: friends list, pending friend requests, and the
/// leaderboard that ranks all friends (plus the current user) by the selected metric.
@MainActor
class FriendViewModel: ObservableObject {
    /// The live profile of the currently logged-in user, kept up-to-date via Firebase listener.
    @Published var currentUser: User
    /// Full `User` objects for each accepted friend.
    @Published var friends: [User] = []
    /// Full `User` objects for incoming friend requests not yet accepted or declined.
    @Published var pendingRequests: [User] = []
    
    /// Which stat column is currently highlighted on the leaderboard.
    @Published var selectedMetric: LeaderboardMetric = .streaks
    /// Which time window is used to compute step/distance scores.
    @Published var selectedTimeframe: LeaderboardTimeframe = .weekly
    
    @Published var alertMessage: String = ""
    @Published var showAlert: Bool = false
    /// `true` while a friend request is being sent to Firebase.
    @Published var isProcessing: Bool = false

    private let dbRef = Database.database().reference()

    /// A sorted list of all friends plus the current user, ranked by `selectedMetric`.
    /// Always includes the current user so they can see their own standing.
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
    
    /// Safely decodes a `User` from a raw Firebase dictionary by supplying default values
    /// for any missing fields. This prevents crashes when reading profiles created by older
    /// app versions that didn't persist every field.
    private func safeDecodeUser(from dict: [String: Any], key: String) -> User? {
        var safeDict = dict
        if safeDict["id"] == nil { safeDict["id"] = key }
        if safeDict["username"] == nil { safeDict["username"] = "Unknown" }
        if safeDict["friendCode"] == nil { safeDict["friendCode"] = "" }
        if safeDict["points"] == nil { safeDict["points"] = 0 }
        if safeDict["currentStreak"] == nil { safeDict["currentStreak"] = 0 }
        if safeDict["dailySteps"] == nil { safeDict["dailySteps"] = 0 }
        if safeDict["dailyStepTarget"] == nil { safeDict["dailyStepTarget"] = 5000 }
        if safeDict["friendList"] == nil { safeDict["friendList"] = [String]() }
        if safeDict["pendingFriendRequests"] == nil { safeDict["pendingFriendRequests"] = [String]() }
        if safeDict["unlockedCustomizations"] == nil { safeDict["unlockedCustomizations"] = [String]() }
        if safeDict["equippedCustomizations"] == nil { safeDict["equippedCustomizations"] = [String: String]() }
        if safeDict["claimedWaypoints"] == nil { safeDict["claimedWaypoints"] = [String: Bool]() }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: safeDict),
              let user = try? JSONDecoder().decode(User.self, from: jsonData) else {
            return nil
        }
        return user
    }
    
    /// Attaches a real-time Firebase listener to the current user's node.
    /// Whenever the database record changes (e.g. a friend accepts a request),
    /// this method refreshes `currentUser` and triggers a fetch of updated friend profiles.
    private func listenForFriendUpdates() {
        dbRef.child("users").child(currentUser.id).observe(.value) { [weak self] snapshot in
            guard let self = self, let dict = snapshot.value as? [String: Any] else { return }
            
            if let updatedUser = self.safeDecodeUser(from: dict, key: snapshot.key) {
                self.currentUser = updatedUser
                Task { await self.fetchDetailedUsers(friendIds: updatedUser.friendList, requestIds: updatedUser.pendingFriendRequests) }
            }
        }
    }
    
    /// Fetches full `User` profiles for the given friend and request UIDs in parallel.
    /// Results replace the `friends` and `pendingRequests` arrays entirely.
    private func fetchDetailedUsers(friendIds: [String], requestIds: [String]) async {
        var fetchedFriends: [User] = []; var fetchedRequests: [User] = []
        
        for fid in friendIds {
            if let snap = try? await dbRef.child("users").child(fid).getData(),
               let data = snap.value as? [String: Any],
               let u = self.safeDecodeUser(from: data, key: snap.key) {
                fetchedFriends.append(u)
            }
        }
        for rid in requestIds {
            if let snap = try? await dbRef.child("users").child(rid).getData(),
               let data = snap.value as? [String: Any],
               let u = self.safeDecodeUser(from: data, key: snap.key) {
                fetchedRequests.append(u)
            }
        }
        
        self.friends = fetchedFriends
        self.pendingRequests = fetchedRequests
    }

    /// Sends a friend request to the user identified by `code`.
    ///
    /// Looks up the target user by their `friendCode` field in Firebase, then appends
    /// the current user's UID to the target's `pendingFriendRequests` array.
    /// Handles error cases: self-add, already-friends, already-sent, user-not-found.
    func sendFriendRequest(to code: String) {
        self.isProcessing = true
        
        let cleanCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !cleanCode.isEmpty else {
            self.isProcessing = false
            return
        }
        
        guard cleanCode != currentUser.friendCode.uppercased() else {
            self.alertMessage = "You cannot add yourself!"
            self.showAlert = true
            self.isProcessing = false
            return
        }
        
        let query = dbRef.child("users").queryOrdered(byChild: "friendCode").queryEqual(toValue: cleanCode)
        
        query.observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard let self = self else { return }
            
            guard snapshot.exists(),
                  let children = snapshot.children.allObjects as? [DataSnapshot],
                  let first = children.first,
                  let dict = first.value as? [String: Any] else {
                
                self.alertMessage = "User not found. Please check the code."
                self.showAlert = true
                self.isProcessing = false
                return
            }
            
            let targetId = dict["id"] as? String ?? first.key
            let targetUsername = dict["username"] as? String ?? "Unknown"
            
            var targetPending = dict["pendingFriendRequests"] as? [String] ?? []
            let targetFriends = dict["friendList"] as? [String] ?? []
            
            if targetFriends.contains(self.currentUser.id) {
                self.alertMessage = "You are already friends with \(targetUsername)."
                self.showAlert = true
                self.isProcessing = false
            } else if targetPending.contains(self.currentUser.id) {
                self.alertMessage = "Request already sent to \(targetUsername)."
                self.showAlert = true
                self.isProcessing = false
            } else {
                targetPending.append(self.currentUser.id)
                self.dbRef.child("users").child(targetId).child("pendingFriendRequests").setValue(targetPending) { error, _ in
                    if let error = error {
                        self.alertMessage = "Database error: \(error.localizedDescription)"
                    } else {
                        self.alertMessage = "Request successfully sent to \(targetUsername)!"
                    }
                    self.showAlert = true
                    self.isProcessing = false
                }
            }
        }) { [weak self] error in
            self?.alertMessage = "Permission Denied: \(error.localizedDescription)"
            self?.showAlert = true
            self?.isProcessing = false
        }
    }

    /// Accepts an incoming friend request from `user`.
    /// Optimistically updates both local arrays, then persists the mutual
    /// friendship to both users' `friendList` nodes in Firebase.
    func acceptRequest(from user: User) {
        if !currentUser.friendList.contains(user.id) {
            currentUser.friendList.append(user.id)
            friends.append(user)
        }
        currentUser.pendingFriendRequests.removeAll { $0 == user.id }
        pendingRequests.removeAll { $0.id == user.id }
        
        let updates: [String: Any] = [
            "users/\(currentUser.id)/friendList": currentUser.friendList,
            "users/\(currentUser.id)/pendingFriendRequests": currentUser.pendingFriendRequests
        ]
        
        Task {
            try? await dbRef.updateChildValues(updates)
            
            var targetFriendList = user.friendList
            if !targetFriendList.contains(currentUser.id) {
                targetFriendList.append(currentUser.id)
                try? await dbRef.child("users").child(user.id).child("friendList").setValue(targetFriendList)
            }
        }
    }

    /// Declines an incoming friend request, removing the requester from
    /// `pendingFriendRequests` both locally and in Firebase.
    func declineRequest(from user: User) {
        // Optimistic UI Update
        currentUser.pendingFriendRequests.removeAll { $0 == user.id }
        pendingRequests.removeAll { $0.id == user.id }
        
        Task {
            try? await dbRef.child("users").child(currentUser.id).child("pendingFriendRequests").setValue(currentUser.pendingFriendRequests)
        }
    }
    
    /// Removes `user` from the current user's friend list and also removes the current
    /// user from the friend's list to keep the relationship symmetric.
    func removeFriend(_ user: User) {
        currentUser.friendList.removeAll { $0 == user.id }
        friends.removeAll { $0.id == user.id }
        
        Task {
            try? await dbRef.child("users").child(currentUser.id).child("friendList").setValue(currentUser.friendList)
            var targetFriendList = user.friendList
            targetFriendList.removeAll { $0 == currentUser.id }
            try? await dbRef.child("users").child(user.id).child("friendList").setValue(targetFriendList)
        }
    }
}

// MARK: - Leaderboard Helpers

extension User {
    /// Returns an estimated step count for the given timeframe.
    /// For weekly/monthly, the streak is used as a multiplier to approximate past activity
    /// (since only `dailySteps` is stored, not a full history).
    func actualSteps(for timeframe: LeaderboardTimeframe) -> Int {
        switch timeframe {
        case .daily: return self.dailySteps
        case .weekly: return self.dailySteps + (self.currentStreak * 1000)
        case .monthly: return self.dailySteps + (self.currentStreak * 5000)
        }
    }
    /// Converts the estimated step count for the timeframe into kilometres.
    /// Uses the standard average stride length of 0.762 m.
    func actualDistance(for timeframe: LeaderboardTimeframe) -> Double { return Double(actualSteps(for: timeframe)) * 0.000762 }
}
