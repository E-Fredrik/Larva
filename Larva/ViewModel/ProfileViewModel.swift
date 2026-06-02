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
    @Published var stepsToday: Int = 5230
    @Published var distanceToday: Double = 3.2

    var friendCount: Int {
        currentUser.friendList.count
    }

    @Published var ownedItems: [ShopItem] = []
    @Published var equippedItems: [String: ShopItem] = [:]
    
    private let dbRef = Database.database().reference()
    private var allShopItemsCache: [String: ShopItem] = [:]

    init(currentUser: User) {
        self.currentUser = currentUser
        
        Task {
            await fetchAllShopItemsCache()
            await fetchUserInventoryAndEquipment()
        }
    }

    func logout() {
        do {
            try Auth.auth().signOut()
            print("Successfully logged out \(currentUser.username)")
        } catch {
            print("Error logging out: \(error.localizedDescription)")
        }
    }
    
    
    private func fetchAllShopItemsCache() async {
        do {
            let snapshot = try await dbRef.child("shopItems").getData()
            guard let children = snapshot.children.allObjects as? [DataSnapshot] else { return }
            
            for child in children {
                if let dict = child.value as? [String: Any],
                   let jsonData = try? JSONSerialization.data(withJSONObject: dict),
                   let item = try? JSONDecoder().decode(ShopItem.self, from: jsonData) {
                    self.allShopItemsCache[item.id] = item
                }
            }
        } catch {
            print("Failed to fetch shop cache")
        }
    }
    
    func fetchUserInventoryAndEquipment() async {
        let userId = currentUser.id
        
        dbRef.child("users").child(userId).observe(.value) { snapshot in
            guard let dict = snapshot.value as? [String: Any] else { return }
            
            if let unlockedIds = dict["unlockedCustomizations"] as? [String] {
                self.ownedItems = unlockedIds.compactMap { self.allShopItemsCache[$0] }
            }
            
            if let equipmentDict = dict["equippedCustomizations"] as? [String: String] {
                var resolvedEquipped: [String: ShopItem] = [:]
                for (itemType, itemId) in equipmentDict {
                    if let item = self.allShopItemsCache[itemId] {
                        resolvedEquipped[itemType] = item
                    }
                }
                self.equippedItems = resolvedEquipped
            }
        }
    }
    
    func equipItem(item: ShopItem) async {
        let userId = currentUser.id
        do {
            try await dbRef.child("users").child(userId)
                .child("equippedCustomizations")
                .child(item.itemType.rawValue)
                .setValue(item.id)
                
            if item.itemType == .appIcon {
                await MainActor.run {
                    changeAppIcon(to: item.id)
                }
            }
        } catch {
            print("Failed to equip item: \(error.localizedDescription)")
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
            print("Failed to unequip item: \(error.localizedDescription)")
        }
    }
    
    private func changeAppIcon(to iconId: String?) {
        guard UIApplication.shared.supportsAlternateIcons else { return }
        UIApplication.shared.setAlternateIconName(iconId) { error in
            if let error = error {
                print("Error changing app icon: \(error.localizedDescription)")
            } else {
                print("Successfully changed app icon to \(iconId ?? "Default")")
            }
        }
    }
}
