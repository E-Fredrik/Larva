//
//  SidebarNavigationView.swift
//  Larva
//
//  Created by student on 28/05/26.
//

import SwiftUI

struct SidebarNavigationView: View {
    @ObservedObject var friendVM: FriendViewModel
    @ObservedObject var questVM: QuestViewModel
    @ObservedObject var shopVM: ShopViewModel
    
    @State private var selectedTab: NavigationTab? = .map
    
    enum NavigationTab {
        case map, quests, shop, friends
    }
    
    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationSplitView {
                List(selection: $selectedTab) {
                    NavigationLink(value: NavigationTab.map) {
                        Label("Map & HUD", systemImage: "map")
                    }
                    NavigationLink(value: NavigationTab.quests) {
                        Label("Quests", systemImage: "flame")
                    }
                    NavigationLink(value: NavigationTab.shop) {
                        Label("Shop", systemImage: "bag")
                    }
                    NavigationLink(value: NavigationTab.friends) {
                        Label("Friends", systemImage: "person.2")
                    }
                }
                .navigationTitle("Larva")
            } detail: {
                switch selectedTab {
                case .map:
                    MapHUDView()
                case .quests:
                    QuestsView(viewModel: questVM)
                case .shop:
                    ShopView(viewModel: shopVM)
                case .friends:
                    FriendsView(viewModel: friendVM)
                case .none:
                    Text("Select an item from the sidebar")
                        .foregroundColor(.secondary)
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }
}
