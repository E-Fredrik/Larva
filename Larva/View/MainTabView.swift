//
//  MainTabView.swift
//  Larva
//
//  Created by student on 28/05/26.
//

import Combine
import SwiftUI

struct MainTabView: View {
    @ObservedObject var friendVM: FriendViewModel
    @ObservedObject var questVM: QuestViewModel
    @ObservedObject var shopVM: ShopViewModel
    
    @StateObject private var profileVM = ProfileViewModel(currentUser:
        User(
        id: "USER-123",
        username: "Maya Chen",
        friendCode: "MCH123",
        points: 2500,
        currentStreak: 89,
        dailyStepTarget: 10000,
        friendList: ["user2", "user3"],
        pendingFriendRequests: [],
        unlockedCustomizations: ["ITEM-001", "ITEM-002"],
        claimedWaypoints: [:]
    ))

    var body: some View {
        TabView {
            MapHUDView()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
            
            QuestsView(viewModel: questVM)
                .tabItem {
                    Label("Quests", systemImage: "flame.fill")
                }
            
            ShopView(viewModel: shopVM)
                .tabItem {
                    Label("Shop", systemImage: "cart.fill")
                }
            
            FriendsView(viewModel: friendVM)
                .tabItem {
                    Label("Friends", systemImage: "person.2.fill")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
        }
        .environmentObject(profileVM)
    }
}
