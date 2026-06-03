//
//  User.swift
//  Larva
//
//  Created by Elifele Fredrik on 28/05/26.
//

import Foundation

/// The central data model for a Larva user, stored in Firebase Realtime Database
/// under the path `users/<uid>`.
///
/// Conforms to `Identifiable` (keyed by `id`) and `Codable` (for Firebase serialisation).
struct User: Identifiable, Codable {
    /// Firebase Authentication UID – used as the primary key in the database.
    var id: String
    /// Display name chosen by the user at sign-up.
    var username: String
    /// Six-character alphanumeric code friends use to send requests (e.g. "A3KT92").
    var friendCode: String
    /// Total accumulated reward points earned through steps, workouts, and quests.
    var points: Int
    /// Number of consecutive days the user has completed all daily quests.
    var currentStreak: Int
    /// The daily step goal the user wants to hit (default 5,000).
    var dailyStepTarget: Int
    /// UIDs of accepted friends.
    var friendList: [String]
    /// UIDs of users who have sent a friend request that has not yet been accepted or declined.
    var pendingFriendRequests: [String]
    /// IDs of shop items the user has already purchased.
    var unlockedCustomizations: [String]
    /// A map of `waypointId -> true` recording which map waypoints the user has physically visited and claimed.
    var claimedWaypoints: [String: Bool]
    /// A map of `itemType -> itemId` recording which customisation item is currently active per category.
    /// Categories are defined by `ShopItem.ItemType` raw values (e.g. "appTheme", "avatarBorder").
    var equippedCustomizations: [String: String]
    /// Steps taken today, synced from `StepTrackerViewModel` to Firebase so friends can compare.
    var dailySteps: Int
    
    /// Historical step, calorie, and distance data keyed by ISO date strings ("yyyy-MM-dd").
    /// Used to display the activity chart on the Profile screen.
    var dailyActivity: [String: ActivityData]?
    
    /// Explicit coding keys so that the struct maps 1-to-1 with the Firebase node keys.
    enum CodingKeys: String, CodingKey {
        case id, username, friendCode, points, currentStreak, dailyStepTarget, friendList, pendingFriendRequests, unlockedCustomizations, claimedWaypoints, equippedCustomizations, dailySteps, dailyActivity
    }
    
    /// Full initialiser – used when creating or fully reconstructing a User from known values
    /// (e.g. when decoding from Firebase or building a complete model in tests).
    init(id: String, username: String, friendCode: String, points: Int, currentStreak: Int, dailyStepTarget: Int = 5000, friendList: [String], pendingFriendRequests: [String], unlockedCustomizations: [String], claimedWaypoints: [String: Bool] = [:], equippedCustomizations: [String: String] = [:], dailySteps: Int = 0, dailyActivity: [String: ActivityData]? = nil) {
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
        self.dailySteps = dailySteps
        self.dailyActivity = dailyActivity
    }
    
    /// Convenience initialiser for testing and previews where a friend code isn't needed.
    /// Sets `friendCode` to a placeholder value "TEST00" and zeroes out step and waypoint data.
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
        self.dailySteps = 0
        self.dailyActivity = nil
    }
    
    /// Lightest convenience initialiser – omits `dailyStepTarget` for legacy preview code.
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
        self.dailySteps = 0
        self.dailyActivity = nil
    }
    
    /// Custom Decodable initialiser that gracefully handles Firebase nodes that may be
    /// missing optional or newly-added fields. Every field uses `decodeIfPresent` with a
    /// sensible default so that older records don't crash the decoder.
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
        dailySteps = try container.decodeIfPresent(Int.self, forKey: .dailySteps) ?? 0        
        dailyActivity = try container.decodeIfPresent([String: ActivityData].self, forKey: .dailyActivity)
    }
}
