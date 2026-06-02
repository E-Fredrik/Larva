//
//  FriendsView.swift
//  LarvaDep
//
//  Created by Eko Nur Cahyo S on 27/05/26.
//

import SwiftUI

struct FriendsView: View {
    @StateObject var viewModel: FriendViewModel
    @State private var showingAddFriend = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        
                        VStack(spacing: 16) {
                            Picker(
                                "Timeframe",
                                selection: $viewModel.selectedTimeframe
                            ) {
                                ForEach(LeaderboardTimeframe.allCases, id: \.self) {
                                    timeframe in
                                    Text(timeframe.rawValue).tag(timeframe)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(LeaderboardMetric.allCases, id: \.self)
                                    { metric in
                                        MetricPill(
                                            title: metric.rawValue,
                                            icon: metricIcon(for: metric),
                                            isSelected: viewModel.selectedMetric
                                                == metric
                                        ) {
                                            withAnimation(
                                                .spring(
                                                    response: 0.3,
                                                    dampingFraction: 0.7
                                                )
                                            ) {
                                                viewModel.selectedMetric = metric
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .padding(.bottom, 8)
                        }
                        .padding(.top, 16)
                        .background(Color(UIColor.systemGroupedBackground))
                        
                        LazyVStack(spacing: 12) {
                            ForEach(
                                Array(viewModel.leaderboard.enumerated()),
                                id: \.element.id
                            ) { index, user in
                                NavigationLink(
                                    destination: FriendProfileView(
                                        viewModel: viewModel,
                                        user: user
                                    )
                                ) {
                                    LeaderboardRow(
                                        user: user,
                                        rank: index + 1,
                                        metric: viewModel.selectedMetric,
                                        timeframe: viewModel.selectedTimeframe,
                                        isCurrentUser: user.id
                                            == viewModel.currentUser.id
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)

                        Spacer().frame(height: 120)
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
                                .background(Color.mint)
                                .clipShape(Circle())
                                .shadow(
                                    color: Color.mint.opacity(0.4),
                                    radius: 10,
                                    x: 0,
                                    y: 5
                                )
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Leaderboard")
            .sheet(isPresented: $showingAddFriend) {
                AddFriendView(viewModel: viewModel)
                    .presentationDetents([.fraction(0.85)])
            }
        }
    }

    private func metricIcon(for metric: LeaderboardMetric) -> String {
        switch metric {
        case .streaks: return "flame.fill"
        case .steps: return "shoeprints.fill"
        case .distance: return "map.fill"
        }
    }
}
