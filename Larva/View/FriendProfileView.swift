//
//  FriendProfileView.swift
//  LarvaDep
//
//  Created by Eko Nur Cahyo S on 27/05/26.
//

import SwiftUI

struct FriendProfileView: View {
    let user: User
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Avatar Placeholder
                Circle()
                    .fill(Color.mint.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .overlay(
                        Text(String(user.username.prefix(1)).uppercased())
                            .font(.system(size: 50, weight: .bold, design: .rounded))
                            .foregroundColor(.mint)
                    )
                    .padding(.top, 40)
                
                VStack(spacing: 8) {
                    Text(user.username)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Friend Code: \(user.id)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Stats Grid
                HStack(spacing: 20) {
                    StatBox(title: "Streak", value: "\(user.currentStreak)", icon: "flame.fill", color: .orange)
                    StatBox(title: "Points", value: "\(user.points)", icon: "star.fill", color: .yellow)
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}
