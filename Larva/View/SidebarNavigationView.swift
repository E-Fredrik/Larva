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

    // NEW: Add HistoryViewModel
    @ObservedObject var historyVM: HistoryViewModel

    @State private var selectedTab: NavigationTab? = .map

    enum NavigationTab {
        case map, history, quests, shop, friends  // Added history to enum
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationSplitView {
                List(selection: $selectedTab) {
                    NavigationLink(value: NavigationTab.map) {
                        Label("Map & HUD", systemImage: "map")
                    }

                    // NEW: Sidebar Link
                    NavigationLink(value: NavigationTab.history) {
                        Label("History", systemImage: "clock.arrow.circlepath")
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
                case .history:
                    HistoryView(viewModel: historyVM)
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
