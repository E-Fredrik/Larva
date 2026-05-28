//
//  FriendsView.swift
//  LarvaDep
//
//  Created by Eko Nur Cahyo S on 27/05/26.
//

import SwiftUI

struct FriendsView: View {
    @StateObject var viewModel = FriendViewModel(
        currentUser: User(
            id: "USER-123",
            username: "Dave",
            friendCode: "ROAM-0F0K",
            points: 2500,
            currentStreak: 7,
            dailyStepTarget: 5000,
            friendList: [],
            pendingFriendRequests: [],
            unlockedCustomizations: []
        )
    )
    
    @State private var selectedTab = 0
    @State private var showingAddFriend = false
    
    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                VStack {
                    Picker("Social View", selection: $selectedTab) {
                        Text("Leaderboard").tag(0)
                        Text("Friends List").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    List {
                        if selectedTab == 0 {
                            ForEach(Array(viewModel.leaderboard.enumerated()), id: \.element.id) { index, user in
                                NavigationLink(destination: FriendProfileView(user: user)) {
                                    LeaderboardRow(rank: index + 1, user: user, isCurrentUser: user.id == viewModel.currentUser.id)
                                }
                            }
                        } else {
                            ForEach(viewModel.friends) { friend in
                                NavigationLink(destination: FriendProfileView(user: friend)) {
                                    FriendRow(user: friend)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
                .navigationTitle("Social")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingAddFriend = true }) {
                            Image(systemName: "person.badge.plus")
                                .foregroundColor(.mint)
                        }
                    }
                }
                .sheet(isPresented: $showingAddFriend) {
                    AddFriendView(viewModel: viewModel)
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }
}
