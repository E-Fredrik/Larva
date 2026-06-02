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

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var currentUser: User
    @Published var stepsToday: Int = 0
    @Published var distanceToday: Double = 0.0

    var friendCount: Int {
        currentUser.friendList.count
    }

    @Published var ownedItems: [ShopItem] = []
    @Published var equippedItems: [String: ShopItem] = [:]
    
    private let dbRef = Database.database(url: "https://larvva-d2753-default-rtdb.asia-southeast1.firebasedatabase.app").reference()
    private var allShopItemsCache: [String: ShopItem] = [:]

    init(currentUser: User) {
        self.currentUser = currentUser
        Task {
            await fetchAllShopItemsCache()
            fetchUserLiveUpdates()
        }
    }
    
    
    var currentAppTheme: ColorScheme? {
        guard let themeItem = equippedItems[ShopItem.ItemType.appTheme.rawValue] else { return nil }
        if themeItem.id == "ITEM-001" || themeItem.id == "ITEM-005" { return .dark }
        if themeItem.id == "ITEM-004" { return .light }
        return nil
    }
    
    var currentAppTint: Color {
        guard let themeItem = equippedItems[ShopItem.ItemType.appTheme.rawValue] else { return .mint }
        if themeItem.id == "ITEM-001" { return .purple }
        if themeItem.id == "ITEM-004" { return .blue }
        if themeItem.id == "ITEM-005" { return .orange }
        return .mint
    }


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
