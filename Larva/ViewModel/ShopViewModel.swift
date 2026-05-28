//
//  ShopViewModel.swift
//  Larva
//
//  Created by student on 28/05/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ShopViewModel: ObservableObject {
    @Published var currentUser: User
    @Published var storeItems: [ShopItem] = []
    
    init(currentUser: User) {
        self.currentUser = currentUser
        loadStoreItems()
    }
    
    private func loadStoreItems() {
        // Updated to use your exact parameter names: 'cost' and 'itemType'
        storeItems = [
            ShopItem(id: "theme_midnight", name: "Midnight Mint", description: "A dark mode map with glowing mint accents.", cost: 500, itemType: .mapTheme),
            ShopItem(id: "theme_surabaya", name: "Surabaya Heat", description: "Warm pastel orange and yellow map routes.", cost: 800, itemType: .mapTheme),
            ShopItem(id: "border_gold", name: "Golden Frame", description: "A shiny gold border for your leaderboard avatar.", cost: 300, itemType: .avatarBorder),
            ShopItem(id: "icon_retro", name: "Retro Larva", description: "An old-school pixelated app icon.", cost: 1200, itemType: .appIcon)
        ]
    }
    
    func purchase(item: ShopItem) {
        //Checks if they already own it
        guard !currentUser.unlockedCustomizations.contains(item.id) else { return }
        
        //Checks if they have enough points
        guard currentUser.points >= item.cost else {
            print("Not enough points to buy \(item.name)!")
            return
        }
        
        //Process the transaction
        currentUser.points -= item.cost
        currentUser.unlockedCustomizations.append(item.id)
        print("Successfully purchased \(item.name)! Remaining balance: \(currentUser.points)")
        
        //Firebase: Sync updated points and unlocked items array here
    }
    
    func owns(item: ShopItem) -> Bool {
        currentUser.unlockedCustomizations.contains(item.id)
    }
}
