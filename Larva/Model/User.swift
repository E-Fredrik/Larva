//
//  User.swift
//  LarvaLawas
//
//  Created by Eko Nur Cahyo S on 27/05/26.
//

import Foundation

struct User: Identifiable, Codable {
    var id: String
    var username: String
    var friendCode: String
    var points: Int
    var currentStreak: Int
    var dailyStepTarget: Int
    var friendList: [String]
    var pendingFriendRequests: [String]
    var unlockedCustomizations: [String]
    var claimedWaypoints: [String: Bool]
    
    var equippedCustomizations: [String: String]
    
    enum CodingKeys: String, CodingKey {
        case id, username, friendCode, points, currentStreak, dailyStepTarget, friendList, pendingFriendRequests, unlockedCustomizations, claimedWaypoints, equippedCustomizations
    }
    
    init(id: String, username: String, friendCode: String, points: Int, currentStreak: Int, dailyStepTarget: Int = 5000, friendList: [String], pendingFriendRequests: [String], unlockedCustomizations: [String], claimedWaypoints: [String: Bool] = [:], equippedCustomizations: [String: String] = [:]) {
        self.id = id
        self.username = username
        self.friendCode = friendCode
        self.points = points
        self.currentStreak = currentStreak
        self.dailyStepTarget = dailyStepTarget
        self.friendList = friendList
        self.pendingFriendRequests = pendingFriendRequests
        self.unlockedCustomizations = unlockedCustomizations
        self.claimedWaypoints = claimedWaypoints
        self.equippedCustomizations = equippedCustomizations
    }
    
    init(id: String, username: String, points: Int, currentStreak: Int, dailyStepTarget: Int = 5000, friendList: [String], pendingFriendRequests: [String], unlockedCustomizations: [String]) {
        self.id = id
        self.username = username
        self.friendCode = "TEST00"
        self.points = points
        self.currentStreak = currentStreak
        self.dailyStepTarget = dailyStepTarget
        self.friendList = friendList
        self.pendingFriendRequests = pendingFriendRequests
        self.unlockedCustomizations = unlockedCustomizations
        self.claimedWaypoints = [:]
        self.equippedCustomizations = [:]
    }
    
    init(id: String, username: String, points: Int, currentStreak: Int, friendList: [String], pendingFriendRequests: [String], unlockedCustomizations: [String]) {
        self.id = id
        self.username = username
        self.friendCode = "TEST00"
        self.points = points
        self.currentStreak = currentStreak
        self.dailyStepTarget = 5000
        self.friendList = friendList
        self.pendingFriendRequests = pendingFriendRequests
        self.unlockedCustomizations = unlockedCustomizations
        self.claimedWaypoints = [:]
        self.equippedCustomizations = [:]
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        friendCode = try container.decodeIfPresent(String.self, forKey: .friendCode) ?? ""
        points = try container.decodeIfPresent(Int.self, forKey: .points) ?? 0
        currentStreak = try container.decodeIfPresent(Int.self, forKey: .currentStreak) ?? 0
        dailyStepTarget = try container.decodeIfPresent(Int.self, forKey: .dailyStepTarget) ?? 5000
        friendList = try container.decodeIfPresent([String].self, forKey: .friendList) ?? []
        pendingFriendRequests = try container.decodeIfPresent([String].self, forKey: .pendingFriendRequests) ?? []
        unlockedCustomizations = try container.decodeIfPresent([String].self, forKey: .unlockedCustomizations) ?? []
        claimedWaypoints = try container.decodeIfPresent([String: Bool].self, forKey: .claimedWaypoints) ?? [:]
        equippedCustomizations = try container.decodeIfPresent([String: String].self, forKey: .equippedCustomizations) ?? [:]
    }
}
