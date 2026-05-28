//
//  MainTabView.swift
//  Larva
//
//  Created by student on 28/05/26.
//

import SwiftUI
import Combine

struct MainTabView: View {
    @ObservedObject var friendVM: FriendViewModel
    @ObservedObject var questVM: QuestViewModel
    @ObservedObject var shopVM: ShopViewModel
    
    var body: some View {
        TabView{
            MapHUDView()
                .tabItem{
                    Label("Map", systemImage: "map.fill")
                }
            QuestsView(viewModel: questVM)
                .tabItem {
                    Label("Quests", systemImage: "flame.fill")
                }
            ShopView(viewModel: shopVM)
                .tabItem{
                 Label("Shop", systemImage: "cart.fill")
                }
            FriendsView()
                .tabItem{
                    Label("Friends", systemImage: "person.2.fill")
                }
        }
    }
}

#Preview {
    MainTabView(
        friendVM: FriendViewModel(currentUser: User(id: "1", username: "Kenjo", points: 100, currentStreak: 100, friendList: [], pendingFriendRequests: [], unlockedCustomizations: [])),
        questVM: QuestViewModel(currentUser: User(id: "1", username: "Kenjo", points: 100, currentStreak: 100, friendList: [], pendingFriendRequests: [], unlockedCustomizations: [])),
        shopVM: ShopViewModel(currentUser: User(id: "1", username: "Kenjo", points: 2500, currentStreak: 100, friendList: [], pendingFriendRequests: [], unlockedCustomizations: []))
    )
}
