//
//  FriendProfileView.swift
//  LarvaDep
//
//  Created by Eko Nur Cahyo S on 27/05/26.
//

import SwiftUI

/// A detailed profile screen for a specific user, pushed from the leaderboard.
///
/// If `user.id` matches the current logged-in user, this view acts as a "Your Stats" screen
/// (hiding the "Remove Friend" button). Otherwise, it displays a friend's stats and
/// provides the option to remove them.
struct FriendProfileView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: FriendViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    
    let user: User
    
    /// Ensures we always display the most up-to-date local data if the viewed profile
    /// belongs to the current user (in case points/streak just changed).
    private var activeUser: User {
        user.id == profileVM.currentUser.id ? profileVM.currentUser : user
    }

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    VStack(spacing: 16) {
                        CustomAvatarView(user: activeUser, size: 100)
                            .padding(.top, 10)
                        
                        VStack(spacing: 6) {
                            Text(activeUser.username)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            HStack(spacing: 6) {
                                Image(systemName: "person.badge.key.fill")
                                    .font(.caption)
                                Text("Code: \(activeUser.friendCode)")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(24)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    
                    HStack(spacing: 16) {
                        FriendStatCard(title: "Streak", value: "\(activeUser.currentStreak)", icon: "flame.fill", color: .orange)
                        FriendStatCard(title: "Points", value: "\(activeUser.points)", icon: "star.fill", color: .yellow)
                    }

                    if activeUser.id != profileVM.currentUser.id {
                        Button(action: {
                            viewModel.removeFriend(activeUser)
                            dismiss()
                        }) {
                            Text("Remove Friend")
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                    }
                    
                    Spacer().frame(height: 100)
                }
                .padding()
            }
            
            VStack {
                Spacer()
                Text(activeUser.id == profileVM.currentUser.id ? "Keep up the great work and stay active!" : "Check in on your friends to see their progress and stay motivated!")
                    .font(.footnote)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: -5)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
            }
        }
        .navigationTitle(activeUser.id == profileVM.currentUser.id ? "Your Stats" : "Friend Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}
