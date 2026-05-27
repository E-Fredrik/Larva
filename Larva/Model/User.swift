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
    var points: Int
    var currentStreak: Int
    var friendList: [String]
    var pendingFriendRequests: [String]
    var unlockedCustomizations: [String]
}
