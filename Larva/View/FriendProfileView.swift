//
//  FriendProfileView.swift
//  LarvaDep
//
//  Created by Eko Nur Cahyo S on 27/05/26.
//

import SwiftUI

struct FriendProfileView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: FriendViewModel
    
    let user: User

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    VStack(spacing: 16) {
                        Circle()
                            .fill(Color.mint.opacity(0.15))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text(String(user.username.prefix(1)).uppercased())
                                    .font(.system(size: 40, weight: .bold, design: .rounded))
                                    .foregroundColor(.mint)
                            )
                            .overlay(Circle().stroke(Color.mint.opacity(0.5), lineWidth: 2))
                            .padding(.top, 10)
                        
                        VStack(spacing: 6) {
                            Text(user.username)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            HStack(spacing: 6) {
                                Image(systemName: "person.badge.key.fill")
                                    .font(.caption)
                                Text("Code: \(user.friendCode)")
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
                        FriendStatCard(title: "Streak", value: "\(user.currentStreak)", icon: "flame.fill", color: .orange)
                        FriendStatCard(title: "Points", value: "\(user.points)", icon: "star.fill", color: .yellow)
                    }

                    Button(action: {
                        viewModel.removeFriend(user)
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
                    
                    Spacer().frame(height: 100)
                }
                .padding()
            }
            
            VStack {
                Spacer()
                Text("Check in on your friends to see their progress and stay motivated!")
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
        .navigationTitle("Friend Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}
