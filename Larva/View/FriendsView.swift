//
//  FriendsView.swift
//  Larva
//
//  Created by Eko Nur Cahyo S on 27/05/26.
//

import SwiftUI

/// The social hub of the application.
///
/// Displays the user's friend code, incoming pending friend requests, and a ranked
/// leaderboard of accepted friends. A floating action button (FAB) in the bottom
/// right opens the `AddFriendView` sheet.
struct FriendsView: View {
    @ObservedObject var viewModel: FriendViewModel
    @State private var showingAddFriend = false
    @EnvironmentObject var profileVM: ProfileViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        VStack(spacing: 12) {
                            Image(systemName: "person.2.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(profileVM.currentAppTint)
                            
                            Text("Your Friend Code")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(viewModel.currentUser.friendCode)
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(12)
                        }
                        .padding(.top, 20)
                        
                        if !viewModel.pendingRequests.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Pending Requests (\(viewModel.pendingRequests.count))")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ForEach(viewModel.pendingRequests) { reqUser in
                                    HStack {
                                        Text(reqUser.username).fontWeight(.semibold)
                                        Spacer()
                                        Button("Accept") { viewModel.acceptRequest(from: reqUser) }
                                            .buttonStyle(.borderedProminent)
                                            .tint(profileVM.currentAppTint)
                                        Button("Decline") { viewModel.declineRequest(from: reqUser) }
                                            .buttonStyle(.bordered)
                                            .tint(.red)
                                    }
                                    .padding()
                                    .background(Color(UIColor.secondarySystemGroupedBackground))
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Leaderboard")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                Picker("Timeframe", selection: $viewModel.selectedTimeframe) {
                                    ForEach(LeaderboardTimeframe.allCases, id: \.self) { timeframe in
                                        Text(timeframe.rawValue).tag(timeframe)
                                    }
                                }
                                .pickerStyle(.segmented)
                                
                                Picker("Metric", selection: $viewModel.selectedMetric) {
                                    ForEach(LeaderboardMetric.allCases, id: \.self) { metric in
                                        Text(metric.rawValue).tag(metric)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                            .padding(.horizontal)
                            
                            if viewModel.leaderboard.isEmpty {
                                Text("Add friends to see them on the leaderboard!")
                                    .foregroundColor(.secondary)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .center)
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(Array(viewModel.leaderboard.enumerated()), id: \.element.id) { index, user in
                                        NavigationLink(destination: FriendProfileView(viewModel: viewModel, user: user)) {
                                            LeaderboardRow(
                                                user: user,
                                                rank: index + 1,
                                                metric: viewModel.selectedMetric,
                                                timeframe: viewModel.selectedTimeframe,
                                                isCurrentUser: user.id == viewModel.currentUser.id
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        Spacer().frame(height: 100)
                    }
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showingAddFriend = true }) {
                            Image(systemName: "person.badge.plus")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(profileVM.currentAppTint) 
                                .clipShape(Circle())
                                .shadow(color: profileVM.currentAppTint.opacity(0.4), radius: 10, x: 0, y: 5)
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Friends")
            .sheet(isPresented: $showingAddFriend) {
                AddFriendView(viewModel: viewModel)
                    .presentationDetents([.fraction(0.85)])
            }
        }
    }
}
