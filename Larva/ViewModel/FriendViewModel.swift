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
    @Published var selectedTimeframe: LeaderboardTimeframe = .daily
    
    @Published var alertMessage: String = ""
    @Published var showAlert: Bool = false

    private let dbRef = Database.database(url: "https://larvva-d2753-default-rtdb.asia-southeast1.firebasedatabase.app").reference()
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
            
            let fList = dict["friendList"] as? [String] ?? []
            let pRequests = dict["pendingFriendRequests"] as? [String] ?? []
            
            self.currentUser.friendList = fList
            self.currentUser.pendingFriendRequests = pRequests
            
            Task { await self.fetchDetailedUsers(friendIds: fList, requestIds: pRequests) }
        }
    }
    
    private func fetchDetailedUsers(friendIds: [String], requestIds: [String]) async {
        var fetchedFriends: [User] = []; var fetchedRequests: [User] = []
        
        for fid in friendIds {
            if let snap = try? await dbRef.child("users").child(fid).getData(),
               let data = snap.value as? [String: Any],
               let jsonData = try? JSONSerialization.data(withJSONObject: data),
               let u = try? JSONDecoder().decode(User.self, from: jsonData) {
                fetchedFriends.append(u)
            }
        }
        
        for rid in requestIds {
            if let snap = try? await dbRef.child("users").child(rid).getData(),
               let data = snap.value as? [String: Any],
               let jsonData = try? JSONSerialization.data(withJSONObject: data),
               let u = try? JSONDecoder().decode(User.self, from: jsonData) {
                fetchedRequests.append(u)
            }
        }
        self.friends = fetchedFriends
        self.pendingRequests = fetchedRequests
    }

    func sendFriendRequest(to code: String) async {
            guard !code.isEmpty else { return }
            let cleanCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard cleanCode != currentUser.friendCode else {
                self.alertMessage = "You cannot add yourself!"
                self.showAlert = true
                return
            }
            
            do {
                let query = dbRef.child("users").queryOrdered(byChild: "friendCode").queryEqual(toValue: cleanCode)
                let snapshot = try await query.getData()
                
                guard snapshot.exists(),
                      let children = snapshot.children.allObjects as? [DataSnapshot],
                      let firstChild = children.first,
                      let dict = firstChild.value as? [String: Any] else {
                    
                    self.alertMessage = "User with code \(cleanCode) not found."
                    self.showAlert = true
                    return
                }
                
                let jsonData = try JSONSerialization.data(withJSONObject: dict)
                var targetUser = try JSONDecoder().decode(User.self, from: jsonData)
                
                if targetUser.friendList.contains(currentUser.id) {
                    self.alertMessage = "You are already friends with \(targetUser.username)."
                } else if targetUser.pendingFriendRequests.contains(currentUser.id) {
                    self.alertMessage = "Request already sent to \(targetUser.username)."
                } else {
                    targetUser.pendingFriendRequests.append(currentUser.id)
                    try await dbRef.child("users").child(targetUser.id).child("pendingFriendRequests").setValue(targetUser.pendingFriendRequests)
                    self.alertMessage = "Request successfully sent to \(targetUser.username)!"
                }
                
            } catch let DecodingError.dataCorrupted(context) {
                print("❌ Decoding Error: Data Corrupted: \(context)")
                self.alertMessage = "Data format error."
            } catch let DecodingError.keyNotFound(key, context) {
                print("❌ Decoding Error: Key '\(key.stringValue)' not found: \(context.debugDescription)")
                self.alertMessage = "Database error: Missing data."
            } catch let DecodingError.typeMismatch(type, context) {
                print("❌ Decoding Error: Type mismatch for type \(type): \(context.debugDescription)")
                self.alertMessage = "Database error: Wrong data type."
            } catch {
                print("❌ Firebase / Network Error: \(error.localizedDescription)")
                self.alertMessage = "Error sending request: \(error.localizedDescription)"
            }
            
            self.showAlert = true
        }

    func acceptRequest(from user: User) {
        if !currentUser.friendList.contains(user.id) { currentUser.friendList.append(user.id) }
        currentUser.pendingFriendRequests.removeAll { $0 == user.id }
        
        Task {
            do {
                try await dbRef.child("users").child(currentUser.id).child("friendList").setValue(currentUser.friendList)
                try await dbRef.child("users").child(currentUser.id).child("pendingFriendRequests").setValue(currentUser.pendingFriendRequests)
                
                var targetFriendList = user.friendList
                if !targetFriendList.contains(currentUser.id) {
                    targetFriendList.append(currentUser.id)
                    try await dbRef.child("users").child(user.id).child("friendList").setValue(targetFriendList)
                }
            } catch { print("Error accepting request") }
        }
    }

    func declineRequest(from user: User) {
        currentUser.pendingFriendRequests.removeAll { $0 == user.id }
        Task {
            do {
                try await dbRef.child("users").child(currentUser.id).child("pendingFriendRequests").setValue(currentUser.pendingFriendRequests)
            } catch { print("Error declining request") }
        }
    }
    
    func removeFriend(_ user: User) {
        currentUser.friendList.removeAll { $0 == user.id }
        
        Task {
            do {
                try await dbRef.child("users").child(currentUser.id).child("friendList").setValue(currentUser.friendList)
                var targetFriendList = user.friendList
                if targetFriendList.contains(currentUser.id) {
                    targetFriendList.removeAll { $0 == currentUser.id }
                    try await dbRef.child("users").child(user.id).child("friendList").setValue(targetFriendList)
                }
            } catch {
                print("Error removing friend: \(error)")
            }
        }
    }
}

extension User {
    func actualSteps(for timeframe: LeaderboardTimeframe) -> Int {
        let baseSteps = self.dailySteps
        switch timeframe {
        case .daily: return baseSteps
        case .weekly: return baseSteps + (self.currentStreak * 4000)
        case .monthly: return baseSteps + (self.currentStreak * 15000)
        }
    }
    func actualDistance(for timeframe: LeaderboardTimeframe) -> Double {
        return Double(actualSteps(for: timeframe)) * 0.000762
    }
}
