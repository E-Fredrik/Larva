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

    // NEW: Add HistoryViewModel
    @ObservedObject var historyVM: HistoryViewModel

    var body: some View {
        TabView {
            MapHUDView()
                .tabItem { Label("Map", systemImage: "map.fill") }

            HistoryView(viewModel: historyVM)
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }

            QuestsView(viewModel: questVM)
                .tabItem { Label("Quests", systemImage: "flame.fill") }

            ShopView(viewModel: shopVM)
                .tabItem { Label("Shop", systemImage: "cart.fill") }

            FriendsView(viewModel: friendVM)
                .tabItem { Label("Friends", systemImage: "person.2.fill") }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
        }
    }
}
