//
//  ProfileViewModel.swift
//  Larva
//
//  Created by student on 28/05/26.
//

import Combine
import FirebaseAuth
import FirebaseDatabase
import Foundation
import SwiftUI

/// Central view model for the user's profile screen.
///
/// Responsibilities:
///  - Keeps a live `currentUser` snapshot in sync with Firebase.
///  - Resolves which shop items the user owns and which are equipped.
///  - Exposes computed tint colour and gradient used app-wide via `EnvironmentObject`.
@MainActor
class ProfileViewModel: ObservableObject {
    /// The current user's data, kept live via `fetchUserLiveUpdates`.
    @Published var currentUser: User
    /// Today's step count, mirrored from Firebase so the profile chart stays current.
    @Published var stepsToday: Int = 0
    @Published var distanceToday: Double = 0.0

    /// Derived count of accepted friends (read-only convenience).
    var friendCount: Int {
        currentUser.friendList.count
    }

    /// Shop items the user has purchased and can equip.
    @Published var ownedItems: [ShopItem] = []
    /// A map of `itemType -> ShopItem` for items that are currently equipped.
    @Published var equippedItems: [String: ShopItem] = [:]
    
    private let dbRef = Database.database(url: "https://larvva-d2753-default-rtdb.asia-southeast1.firebasedatabase.app").reference()
    /// In-memory cache of all shop items keyed by ID.
    /// Populated once at init so equipped items can be resolved without extra network calls.
    var allShopItemsCache: [String: ShopItem] = [:]

    init(currentUser: User) {
        self.currentUser = currentUser
        Task {
            await fetchAllShopItemsCache()
            fetchUserLiveUpdates()
        }
    }
    
    /// The primary accent colour for the entire app, driven by the currently equipped
    /// `appTheme` shop item. Defaults to `.mint` if no theme is equipped.
    var currentAppTint: Color {
        guard let themeItem = equippedItems[ShopItem.ItemType.appTheme.rawValue],
              let hexString = themeItem.colorHex else {
            return .mint
        }
        return Color(hex: hexString) ?? .mint
    }
    
    /// A subtle two-colour gradient applied as the background across authenticated screens.
    /// Fades from a tinted overlay at the top to the system grouped background at the bottom.
    var currentAppGradient: LinearGradient {
        LinearGradient(
            colors: [currentAppTint.opacity(0.2), Color(UIColor.systemGroupedBackground)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Returns the border `Color` for `user`'s avatar if they have an `avatarBorder`
    /// customisation equipped. Returns `nil` if no border is set, so the avatar renders without one.
    func getBorderColor(for user: User) -> Color? {
        guard let borderId = user.equippedCustomizations[ShopItem.ItemType.avatarBorder.rawValue],
              let item = allShopItemsCache[borderId],
              let hex = item.colorHex else {
            return nil
        }
        return Color(hex: hex)
    }

    /// One-time fetch of all shop items into `allShopItemsCache` at startup.
    /// Only `appTheme` and `avatarBorder` items are stored since those are the only
    /// types that affect the visual appearance of other views.
    private func fetchAllShopItemsCache() async {
        do {
            let snapshot = try await dbRef.child("shopItems").getData()
            guard let children = snapshot.children.allObjects as? [DataSnapshot] else { return }
            
            for child in children {
                if let dict = child.value as? [String: Any],
                   let jsonData = try? JSONSerialization.data(withJSONObject: dict),
                   let item = try? JSONDecoder().decode(ShopItem.self, from: jsonData) {
                    if item.itemType == .appTheme || item.itemType == .avatarBorder {
                        self.allShopItemsCache[item.id] = item
                    }
                }
            }
        } catch {
            print("Failed to fetch shop cache")
        }
    }
    
    /// Attaches a real-time Firebase listener to `users/<uid>` and manually reads each
    /// field from the raw dictionary. This approach is used instead of full `Codable` decoding
    /// so that partial updates (e.g. only points changing) don't overwrite other local state.
    func fetchUserLiveUpdates() {
        let userId = currentUser.id
        dbRef.child("users").child(userId).observe(.value) { [weak self] snapshot in
            guard let self = self, let dict = snapshot.value as? [String: Any] else { return }
            
            if let username = dict["username"] as? String { self.currentUser.username = username }
            if let friendCode = dict["friendCode"] as? String { self.currentUser.friendCode = friendCode }
            if let points = dict["points"] as? Int { self.currentUser.points = points }
            if let streak = dict["currentStreak"] as? Int { self.currentUser.currentStreak = streak }
            
            self.currentUser.friendList = dict["friendList"] as? [String] ?? []
            self.currentUser.pendingFriendRequests = dict["pendingFriendRequests"] as? [String] ?? []
            
            if let steps = dict["dailySteps"] as? Int {
                self.stepsToday = steps
                // 0.762 m is the average stride length used for distance estimation.
                self.distanceToday = Double(steps) * 0.000762
                self.currentUser.dailySteps = steps
            } else {
                self.stepsToday = 0; self.distanceToday = 0.0; self.currentUser.dailySteps = 0
            }
            
            if let unlockedIds = dict["unlockedCustomizations"] as? [String] {
                self.ownedItems = unlockedIds.compactMap { self.allShopItemsCache[$0] }
                self.currentUser.unlockedCustomizations = unlockedIds
            } else {
                self.ownedItems = []; self.currentUser.unlockedCustomizations = []
            }
            
            // Resolve each equipped item ID to its full `ShopItem` object using the cache.
            let equipmentDict = dict["equippedCustomizations"] as? [String: String] ?? [:]
            var resolvedEquipped: [String: ShopItem] = [:]
            for (itemType, itemId) in equipmentDict {
                if let item = self.allShopItemsCache[itemId] {
                    resolvedEquipped[itemType] = item
                }
            }
            self.equippedItems = resolvedEquipped
            self.currentUser.equippedCustomizations = equipmentDict
        }
    }
    
    /// Sets the given `item` as the currently equipped item for its type (e.g. appTheme).
    /// Writes the item's ID to `equippedCustomizations/<itemType>` in Firebase.
    func equipItem(item: ShopItem) async {
        let userId = currentUser.id
        do {
            try await dbRef.child("users").child(userId)
                .child("equippedCustomizations")
                .child(item.itemType.rawValue)
                .setValue(item.id)
        } catch {
            print("Failed to equip item")
        }
    }
    
    /// Removes the equipped item for the given `itemType` from Firebase,
    /// reverting the slot to its default (unequipped) state.
    func unequipItem(itemType: ShopItem.ItemType) async {
        let userId = currentUser.id
        do {
            try await dbRef.child("users").child(userId)
                .child("equippedCustomizations")
                .child(itemType.rawValue)
                .removeValue()
        } catch {
            print("Failed to unequip item")
        }
    }
}

/// Extends `Color` with a hex string initialiser so shop item `colorHex` fields
/// can be converted directly to a SwiftUI `Color` for tinting.
extension Color {
    /// Creates a `Color` from a 6-digit hex string with an optional leading `#`.
    /// Returns `nil` if the string cannot be parsed as a valid hex colour.
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        var r: Double = 0.0
        var g: Double = 0.0
        var b: Double = 0.0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        if hexSanitized.count == 6 {
            r = Double((rgb & 0xFF0000) >> 16) / 255.0
            g = Double((rgb & 0x00FF00) >> 8) / 255.0
            b = Double(rgb & 0x0000FF) / 255.0
        } else {
            return nil
        }

        self.init(red: r, green: g, blue: b)
    }
}
