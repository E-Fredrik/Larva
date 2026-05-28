//
//  ShopViewModel.swift
//  Larva
//
//  Created by student on 28/05/26.
//

import Combine
import FirebaseDatabase
import Foundation
import SwiftUI

@MainActor
class ShopViewModel: ObservableObject {
    @Published var currentUser: User
    @Published var storeItems: [ShopItem] = []

    private let dbRef = Database.database().reference()

    init(currentUser: User) {
        self.currentUser = currentUser
        loadStoreItems()
    }

    private func loadStoreItems() {
        storeItems = [
            ShopItem(
                id: "theme_midnight",
                name: "Midnight Mint",
                description: "A dark mode map with glowing mint accents.",
                cost: 500,
                itemType: .mapTheme
            ),
            ShopItem(
                id: "theme_surabaya",
                name: "Surabaya Heat",
                description: "Warm pastel orange and yellow map routes.",
                cost: 800,
                itemType: .mapTheme
            ),
            ShopItem(
                id: "border_gold",
                name: "Golden Frame",
                description: "A shiny gold border for your leaderboard avatar.",
                cost: 300,
                itemType: .avatarBorder
            ),
            ShopItem(
                id: "icon_retro",
                name: "Retro Larva",
                description: "An old-school pixelated app icon.",
                cost: 1200,
                itemType: .appIcon
            ),
        ]
    }

    func purchase(item: ShopItem) {
        guard !currentUser.unlockedCustomizations.contains(item.id) else {
            return
        }
        guard currentUser.points >= item.cost else {
            print("Not enough points to buy \(item.name)!")
            return
        }

        //Process local transaction
        currentUser.points -= item.cost
        currentUser.unlockedCustomizations.append(item.id)

        //Sync to Firebase Realtime Database
        Task {
            do {
                try dbRef.child("users").child(currentUser.id).setValue(
                    from: currentUser
                )
                print(
                    "Successfully purchased \(item.name)! Synced to Firebase."
                )
            } catch {
                print(
                    "Error syncing purchase to database: \(error.localizedDescription)"
                )
            }
        }
    }

    func owns(item: ShopItem) -> Bool {
        currentUser.unlockedCustomizations.contains(item.id)
    }
}
