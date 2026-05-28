//
//  ContentView.swift
//  Larva
//
//  Created by Elifele Fredrik on 24/05/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject var friendVM = FriendViewModel(currentUser: User(id: "1", username: "Kenjo", points: 2500, currentStreak: 100, friendList: [], pendingFriendRequests: [], unlockedCustomizations: []))
    @StateObject var questVM = QuestViewModel(currentUser: User(id: "1", username: "Kenjo", points: 2500, currentStreak: 100, friendList: [], pendingFriendRequests: [], unlockedCustomizations: []))
    @StateObject var shopVM = ShopViewModel(currentUser: User(id: "1", username: "Kenjo", points: 2500, currentStreak: 100, friendList: [], pendingFriendRequests: [], unlockedCustomizations: []))
    
    //Detects if it's running on iPhone, iPad, or Apple Watch
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    var body: some View {
        Group{
            if horizontalSizeClass == .regular {
                SidebarNavigationView(friendVM: friendVM, questVM: questVM, shopVM: shopVM)
            }
            else {
                MainTabView(friendVM: friendVM, questVM: questVM, shopVM: shopVM)
            }
        }.tint(.mint)
    }
}

#Preview {
    ContentView()
}
