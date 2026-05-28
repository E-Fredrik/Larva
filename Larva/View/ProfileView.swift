//
//  ProfileView.swift
//  Larva
//
//  Created by student on 28/05/26.
//

import SwiftUI

struct ProfileView: View {
    @StateObject var viewModel = ProfileViewModel(
        currentUser: User(id: "USER-123", username: "Maya Chen", friendCode: "MCH123", points: 2500, currentStreak: 89, dailyStepTarget: 10000, friendList: ["user2", "user3"], pendingFriendRequests: [], unlockedCustomizations: ["theme_midnight", "border_gold"], claimedWaypoints: [:])
    )
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showingSettings = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                if horizontalSizeClass == .regular {
                    iPadLayout
                } else {
                    iPhoneLayout
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.mint)
                    }
                }
            }
            .sheet(isPresented: Binding(
                get: { showingSettings && horizontalSizeClass != .regular },
                set: { showingSettings = $0 }
            )) {
                SettingsView(viewModel: viewModel)
            }
            .popover(isPresented: Binding(
                get: { showingSettings && horizontalSizeClass == .regular },
                set: { showingSettings = $0 }
            )) {
                SettingsView(viewModel: viewModel)
                    .frame(width: 320, height: 280)
            }
        }
    }
        
    private var iPhoneLayout: some View {
        ScrollView {
            VStack(spacing: 24) {
                heroSection
                statsGrid
                friendsBanner
                equippedSection
                
                Spacer().frame(height: 100)
            }
            .padding(.horizontal)
        }
    }
    
    private var iPadLayout: some View {
        HStack(alignment: .top, spacing: 32) {
            ScrollView {
                VStack(spacing: 32) {
                    heroSection
                    statsGrid
                    friendsBanner
                }
                .padding(.horizontal)
            }
            .frame(maxWidth: .infinity)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    equippedSection
                }
                .padding(.horizontal)
                
                Spacer().frame(height: 100)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 24)
    }
    
    
    private var heroSection: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(Color.mint.opacity(0.2))
                .frame(width: 100, height: 100)
                .overlay(
                    Text(String(viewModel.currentUser.username.prefix(1)).uppercased())
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.mint)
                )
                .overlay(
                    Circle().stroke(Color.yellow, lineWidth: 4)
                )
                .padding(.top, 20)
            
            VStack(spacing: 4) {
                Text(viewModel.currentUser.username)
                    .font(.title2)
                    .fontWeight(.bold)

                Text("CODE: \(viewModel.currentUser.friendCode)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
    
    private var statsGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
        return LazyVGrid(columns: columns, spacing: 16) {
            StatCard(title: "Steps Today", value: "\(viewModel.stepsToday)", icon: "shoeprints.fill", color: .mint)
            StatCard(title: "Distance", value: "\(String(format: "%.1f", viewModel.distanceToday)) km", icon: "map.fill", color: .mint)
            StatCard(title: "Current Streak", value: "\(viewModel.currentUser.currentStreak) Days", icon: "flame.fill", color: .orange)
            StatCard(title: "Total Points", value: "\(viewModel.currentUser.points)", icon: "star.fill", color: .yellow)
        }
    }
    
    private var friendsBanner: some View {
        HStack {
            Image(systemName: "person.2.fill")
                .foregroundColor(.mint)
                .font(.title2)
            Text("Friends")
                .font(.headline)
            Spacer()
            Text("\(viewModel.friendCount) Connected")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    private var equippedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Equipped Customizations")
                    .font(.headline)
                Spacer()
                Button("Edit") {
                }
                .font(.subheadline)
                .foregroundColor(.mint)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.equippedCustomization) { item in
                        EquippedItemCard(item: item)
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileView()
}
