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
    
    @Published var alertMessage: String = ""
    @Published var showAlert: Bool = false
    @Published var isProcessing: Bool = false

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
    
    private func listenForFriendUpdates() {
        dbRef.child("users").child(currentUser.id).observe(.value) { [weak self] snapshot in
            guard let self = self, let dict = snapshot.value as? [String: Any] else { return }
            
            if let updatedUser = self.safeDecodeUser(from: dict, key: snapshot.key) {
                self.currentUser = updatedUser
                Task { await self.fetchDetailedUsers(friendIds: updatedUser.friendList, requestIds: updatedUser.pendingFriendRequests) }
            }
        }
    }
    
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

    func declineRequest(from user: User) {
        // Optimistic UI Update
        currentUser.pendingFriendRequests.removeAll { $0 == user.id }
        pendingRequests.removeAll { $0.id == user.id }
        
        Task {
            try? await dbRef.child("users").child(currentUser.id).child("pendingFriendRequests").setValue(currentUser.pendingFriendRequests)
        }
    }
    
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
