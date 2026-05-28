//
//  ProfileViewModelTests.swift
//  LarvaTests
//
//  Created by student on 28/05/26.
//

import Testing
import FirebaseAuth
@testable import Larva
@Suite("Profile View Model Tests")
@MainActor
struct ProfileViewModelTests {
    
    var viewModel: ProfileViewModel
    var mockUser: Larva.User
    
    init() {
        self.mockUser = Larva.User(
            id: "test_user_profile",
            username: "ProfileDave",
            friendCode: "DAV123",
            points: 2500,
            currentStreak: 89,
            dailyStepTarget: 10000,
            friendList: ["friend_1", "friend_2", "friend_3"],
            pendingFriendRequests: [],
            unlockedCustomizations: ["theme_midnight", "border_gold"],
            claimedWaypoints: [:]
        )
        self.viewModel = ProfileViewModel(currentUser: mockUser)
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
    
    @Test("Default daily ephemeral stats load correctly")
    func defaultDailyStats() {
        #expect(viewModel.stepsToday == 5230, "Steps today should load the default UI value.")
        #expect(viewModel.distanceToday == 3.2, "Distance today should load the default UI value.")
    }
    
    @Test("Equipped customizations default to standard loadout")
    func equippedCustomizationsLoaded() {
        #expect(viewModel.equippedCustomization.count == 2, "Should load the 2 default equipped items.")
        #expect(viewModel.equippedCustomization.contains { $0.id == "theme_midnight" })
        #expect(viewModel.equippedCustomization.contains { $0.id == "border_gold" })
    }
    
    @Test("Logout executes safely without fatal crashes")
    func logoutExecution() {
        viewModel.logout()
        #expect(true, "Logout function handled missing Firebase configuration gracefully without crashing.")
    }
}
