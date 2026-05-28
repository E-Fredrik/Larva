//
//  ShopViewModelTests.swift
//  LarvaTests
//
//  Created by student on 28/05/26.
//

import Testing
@testable import Larva
@Suite("Shop View Model Tests")
@MainActor
struct ShopViewModelTests {
    
    var viewModel: ShopViewModel
    var mockUser: User
    
    init() {
        self.mockUser = User(
            id: "test_user_1",
            username: "TestDave",
            friendCode: "TEST00",
            points: 1000,
            currentStreak: 5,
            dailyStepTarget: 5000,
            friendList: [],
            pendingFriendRequests: [],
            unlockedCustomizations: ["pre_owned_item"],
            claimedWaypoints: [:]
        )
        self.viewModel = ShopViewModel(currentUser: mockUser)
    }
    
    @Test("Store items load successfully on initialization")
    func storeItemsLoad() {
        #expect(!viewModel.storeItems.isEmpty, "Store items should be populated upon initialization.")
        #expect(viewModel.storeItems.contains(where: { $0.id == "theme_midnight" }), "Should contain standard shop items from loadStoreItems().")
    }
    
    @Test("The 'owns' function correctly identifies owned items")
    func ownsFunctionLogic() {
        let ownedItem = ShopItem(id: "pre_owned_item", name: "Pre-Owned", description: "", cost: 100, itemType: .mapTheme)
        let unownedItem = ShopItem(id: "theme_midnight", name: "Midnight Mint", description: "", cost: 500, itemType: .mapTheme)
        
        #expect(viewModel.owns(item: ownedItem), "Should return true for items explicitly in the unlockedCustomizations array.")
        #expect(!viewModel.owns(item: unownedItem), "Should return false for unowned items.")
    }
    
    @Test("Successful purchase deducts points and unlocks item")
    func successfulPurchase() {
        guard let itemToBuy = viewModel.storeItems.first(where: { $0.id == "theme_midnight" }) else {
            Issue.record("Could not find test item in the store.")
            return
        }
        
        viewModel.purchase(item: itemToBuy)
        
        #expect(viewModel.currentUser.points == 500, "Points should be deducted (1000 initial - 500 cost = 500).")
        #expect(viewModel.currentUser.unlockedCustomizations.contains("theme_midnight"), "Item ID should be successfully added to unlocked list.")
    }
    
    @Test("Purchase fails and protects points if user is broke")
    func insufficientPointsPurchase() {
        viewModel.currentUser.points = 100
        
        guard let expensiveItem = viewModel.storeItems.first(where: { $0.id == "icon_retro" }) else {
            Issue.record("Could not find expensive test item.")
            return
        }
        
        viewModel.purchase(item: expensiveItem)
        
        #expect(viewModel.currentUser.points == 100, "Points should NOT be deducted.")
        #expect(!viewModel.currentUser.unlockedCustomizations.contains(expensiveItem.id), "Item should NOT be unlocked.")
    }
    
    @Test("Purchase fails and ignores transaction if item is already owned")
    func alreadyOwnedPurchase() {
        guard let itemToBuy = viewModel.storeItems.first(where: { $0.id == "theme_midnight" }) else { return }
        
        viewModel.currentUser.unlockedCustomizations.append(itemToBuy.id)
        let initialCustomizationCount = viewModel.currentUser.unlockedCustomizations.count
        
        viewModel.purchase(item: itemToBuy)
        
        #expect(viewModel.currentUser.points == 1000, "Points should NOT be deducted for an already owned item.")
        #expect(viewModel.currentUser.unlockedCustomizations.count == initialCustomizationCount, "Duplicate items should not be added to the array.")
    }
}
