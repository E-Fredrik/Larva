//
//  ProfileView.swift
//  Larva
//
//  Created by student on 28/05/26.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var viewModel: ProfileViewModel

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showingSettings = false
    @State private var showingCustomizationSheet = false

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
            .sheet(
                isPresented: Binding(
                    get: { showingSettings && horizontalSizeClass != .regular },
                    set: { showingSettings = $0 }
                )
            ) {
                SettingsView(viewModel: viewModel)
            }
            .popover(
                isPresented: Binding(
                    get: { showingSettings && horizontalSizeClass == .regular },
                    set: { showingSettings = $0 }
                )
            ) {
                SettingsView(viewModel: viewModel)
                    .frame(width: 320, height: 280)
            }
            .sheet(isPresented: $showingCustomizationSheet) {
                CustomizationInventoryView()
                    .environmentObject(viewModel)
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
            
            ZStack {
                Circle()
                    .fill(Color.mint.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Text(String(viewModel.currentUser.username.prefix(1)).uppercased())
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.mint)
                    )
                
                if let borderItem = viewModel.equippedItems[ShopItem.ItemType.avatarBorder.rawValue] {
                    Image(borderItem.id)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 115, height: 115)
                }
            }
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
        let columns = [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
        ]
        return LazyVGrid(columns: columns, spacing: 16) {
            StatCard(
                title: "Steps Today",
                value: "\(viewModel.stepsToday)",
                icon: "shoeprints.fill",
                color: .mint
            )
            StatCard(
                title: "Distance",
                value: "\(String(format: "%.1f", viewModel.distanceToday)) km",
                icon: "map.fill",
                color: .mint
            )
            StatCard(
                title: "Current Streak",
                value: "\(viewModel.currentUser.currentStreak) Days",
                icon: "flame.fill",
                color: .orange
            )
            StatCard(
                title: "Total Points",
                value: "\(viewModel.currentUser.points)",
                icon: "star.fill",
                color: .yellow
            )
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
                    showingCustomizationSheet = true
                }
                .font(.subheadline)
                .foregroundColor(.mint)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    let equippedItemsArray = Array(viewModel.equippedItems.values)
                    
                    if equippedItemsArray.isEmpty {
                        Text("No items equipped.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    } else {
                        ForEach(equippedItemsArray, id: \.id) { item in
                            EquippedItemCard(item: item)
                        }
                    }
                }
            }
        }
    }
}

struct CustomizationInventoryView: View {
    @EnvironmentObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                if viewModel.ownedItems.isEmpty {
                    Text("You don't own any items yet. Visit the shop!")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewModel.ownedItems, id: \.id) { item in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.name)
                                    .font(.headline)
                                Text(item.itemType.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if viewModel.equippedItems[item.itemType.rawValue]?.id == item.id {
                                Button("Unequip") {
                                    Task { await viewModel.unequipItem(itemType: item.itemType) }
                                }
                                .buttonStyle(.bordered)
                                .tint(.red)
                            } else {
                                Button("Equip") {
                                    Task { await viewModel.equipItem(item: item) }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.mint)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Your Inventory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(ProfileViewModel(
            currentUser: User(
                id: "USER-123",
                username: "Maya Chen",
                friendCode: "MCH123",
                points: 2500,
                currentStreak: 89,
                dailyStepTarget: 10000,
                friendList: ["user2", "user3"],
                pendingFriendRequests: [],
                unlockedCustomizations: ["ITEM-001", "ITEM-002"],
                claimedWaypoints: [:]
            )
        ))
}
