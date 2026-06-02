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
                if horizontalSizeClass == .regular { iPadLayout } else { iPhoneLayout }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(viewModel: viewModel)
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
            ScrollView { VStack(spacing: 32) { heroSection; statsGrid; friendsBanner }.padding(.horizontal) }
            .frame(maxWidth: .infinity)
            ScrollView { VStack(alignment: .leading, spacing: 24) { equippedSection }.padding(.horizontal); Spacer().frame(height: 100) }
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 24)
    }

    private var heroSection: some View {
        VStack(spacing: 12) {
            CustomAvatarView(user: viewModel.currentUser, size: 100)
                .padding(.top, 20)

            VStack(spacing: 4) {
                Text(viewModel.currentUser.username).font(.title2).fontWeight(.bold)
                Text("CODE: \(viewModel.currentUser.friendCode)")
                    .font(.caption).foregroundColor(.secondary).padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1)).cornerRadius(8)
            }
        }
    }

    private var statsGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
        return LazyVGrid(columns: columns, spacing: 16) {
            StatCard(title: "Steps Today", value: "\(viewModel.stepsToday)", icon: "shoeprints.fill", color: viewModel.currentAppTint)
            StatCard(title: "Distance", value: "\(String(format: "%.1f", viewModel.distanceToday)) km", icon: "map.fill", color: viewModel.currentAppTint)
            StatCard(title: "Current Streak", value: "\(viewModel.currentUser.currentStreak) Days", icon: "flame.fill", color: .orange)
            StatCard(title: "Total Points", value: "\(viewModel.currentUser.points)", icon: "star.fill", color: .yellow)
        }
    }

    private var friendsBanner: some View {
        HStack {
            Image(systemName: "person.2.fill").foregroundColor(viewModel.currentAppTint).font(.title2)
            Text("Friends").font(.headline)
            Spacer()
            Text("\(viewModel.friendCount) Connected").font(.subheadline).foregroundColor(.secondary)
        }
        .padding().background(Color(UIColor.secondarySystemBackground)).cornerRadius(16)
    }

    private var equippedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Equipped Customizations").font(.headline)
                Spacer()
                Button("Edit") { showingCustomizationSheet = true }
                    .font(.subheadline)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    let equippedItemsArray = Array(viewModel.equippedItems.values)
                    if equippedItemsArray.isEmpty {
                        Text("No items equipped.").font(.subheadline).foregroundColor(.secondary).padding(.top, 8)
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
                    ForEach(ShopItem.ItemType.allCases, id: \.self) { category in
                        Section(header: Text(category == .appTheme ? "App Themes" : "Profile Borders")) {
                            
                            let items = viewModel.ownedItems.filter { $0.itemType == category }
                            if items.isEmpty {
                                Text("No items owned in this category.").font(.caption).foregroundColor(.secondary)
                            } else {
                                ForEach(items, id: \.id) { item in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(item.name).font(.headline)
                                        }
                                        Spacer()
                                        
                                        if viewModel.equippedItems[category.rawValue]?.id == item.id {
                                            Button("Unequip") {
                                                Task { await viewModel.unequipItem(itemType: category) }
                                            }
                                            .buttonStyle(.bordered)
                                            .tint(.red)
                                        } else {
                                            Button("Equip") {
                                                Task { await viewModel.equipItem(item: item) }
                                            }
                                            .buttonStyle(.borderedProminent)
                                            .tint(viewModel.currentAppTint)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Your Inventory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.bold)
                }
            }
        }
    }
}
