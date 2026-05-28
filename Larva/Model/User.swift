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
    var friendList: [String]
    var pendingFriendRequests: [String]
    var unlockedCustomizations: [String]
    
    enum CodingKeys: String, CodingKey {
        case id, username, friendCode, points, currentStreak, friendList, pendingFriendRequests, unlockedCustomizations
    }
    
    init(id: String, username: String, friendCode: String, points: Int, currentStreak: Int, friendList: [String], pendingFriendRequests: [String], unlockedCustomizations: [String]) {
        self.id = id
        self.username = username
        self.friendCode = friendCode
        self.points = points
        self.currentStreak = currentStreak
        self.friendList = friendList
        self.pendingFriendRequests = pendingFriendRequests
        self.unlockedCustomizations = unlockedCustomizations
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        friendCode = try container.decodeIfPresent(String.self, forKey: .friendCode) ?? ""
        
        points = try container.decodeIfPresent(Int.self, forKey: .points) ?? 0
        currentStreak = try container.decodeIfPresent(Int.self, forKey: .currentStreak) ?? 0
        
        friendList = try container.decodeIfPresent([String].self, forKey: .friendList) ?? []
        pendingFriendRequests = try container.decodeIfPresent([String].self, forKey: .pendingFriendRequests) ?? []
        unlockedCustomizations = try container.decodeIfPresent([String].self, forKey: .unlockedCustomizations) ?? []
    }
}
