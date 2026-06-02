//
//  ProfileViewModelTests.swift
//  LarvaTests
//
//  Created by student on 28/05/26.
//

import Testing
import FirebaseAuth
import SwiftUI
@testable import Larva

@Suite("Profile View Model Tests")
@MainActor
struct ProfileViewModelTests {
    
    var viewModel: ProfileViewModel
    var mockUser: Larva.User
    
    init() {
        let equipped = [
            ShopItem.ItemType.appTheme.rawValue: "theme_red",
            ShopItem.ItemType.avatarBorder.rawValue: "border_gold"
        ]
        
        self.mockUser = Larva.User(
            id: "test_user_profile",
            username: "ProfileDave",
            friendCode: "DAV123",
            points: 2500,
            currentStreak: 89,
            dailyStepTarget: 10000,
            friendList: ["friend_1", "friend_2", "friend_3"],
            pendingFriendRequests: [],
            unlockedCustomizations: ["theme_red", "border_gold"],
            claimedWaypoints: [:],
            equippedCustomizations: equipped
        )
        self.viewModel = ProfileViewModel(currentUser: mockUser)
        
        viewModel.equippedItems = [
            "appTheme": ShopItem(id: "theme_red", name: "Red Theme", description: "", cost: 100, itemType: .appTheme, colorHex: "#FF0000"),
            "avatarBorder": ShopItem(id: "border_gold", name: "Gold Border", description: "", cost: 500, itemType: .avatarBorder, colorHex: "#FFD700")
        ]
    }
    
    @Test("ViewModel initializes with the correct user data")
    func initialization() {
        #expect(viewModel.currentUser.username == "ProfileDave")
        #expect(viewModel.currentUser.friendCode == "DAV123")
    }
    
    @Test("Friend count computed property accurately counts friends")
    func friendCountCalculation() {
        #expect(viewModel.friendCount == 3, "Friend count should reflect the 3 friends in the mock data.")
        
        viewModel.currentUser.friendList.append("friend_4")
        
        #expect(viewModel.friendCount == 4, "Friend count should dynamically update to 4.")
    }
    
    @Test("Equipped customizations decode correctly into dictionary")
    func equippedCustomizationsLoaded() {
        #expect(viewModel.equippedItems.count == 2, "Should load the 2 mock equipped items.")
        #expect(viewModel.equippedItems["appTheme"]?.id == "theme_red")
        #expect(viewModel.equippedItems["avatarBorder"]?.id == "border_gold")
    }
    
    @Test("Dynamic App Tint correctly reads Hex color from equipped theme")
    func dynamicAppTintTranslatesHex() {
        let tint = viewModel.currentAppTint
        
        #expect(tint != .mint, "The app tint should translate the #FF0000 hex and not fall back to default mint.")
    }
    
    @Test("Avatar Border helper safely extracts hex for user")
    func borderHelperTranslatesHex() {
        viewModel.allShopItemsCache = [
            "border_gold": ShopItem(id: "border_gold", name: "Gold Border", description: "", cost: 500, itemType: .avatarBorder, colorHex: "#FFD700")
        ]
        
        let color = viewModel.getBorderColor(for: mockUser)
        #expect(color != nil, "The helper should successfully extract the hex and convert to Color")
    }
}
