//
//  ShopView.swift
//  Larva
//
//  Created by student on 28/05/26.
//

import SwiftUI

struct ShopView: View {
    @ObservedObject var viewModel: ShopViewModel
    

    @State private var selectedCategory: ShopItem.ItemType? = nil
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var filteredItems: [ShopItem] {
        if let category = selectedCategory {
            return viewModel.storeItems.filter { $0.itemType == category }
        } else {
            return viewModel.storeItems
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Available Points")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.8))
                            
                            HStack(spacing: 8) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .shadow(color: .yellow.opacity(0.5), radius: 5, x: 0, y: 0)
                                Text("\(viewModel.currentUser.points)")
                                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                                    .foregroundColor(.white)
                            }
                        }
                        Spacer()
                        
                        Image(systemName: "bag.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(24)
                    .background(
                        LinearGradient(
                            colors: [Color.mint, Color.mint.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(24)
                    .shadow(color: Color.mint.opacity(0.3), radius: 10, x: 0, y: 5)
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            CategoryPill(title: "All", isSelected: selectedCategory == nil) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedCategory = nil
                                }
                            }
                            
                            CategoryPill(title: "Map Themes", isSelected: selectedCategory == .mapTheme) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedCategory = .mapTheme
                                }
                            }
                            
                            CategoryPill(title: "Borders", isSelected: selectedCategory == .avatarBorder) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedCategory = .avatarBorder
                                }
                            }
                            
                            CategoryPill(title: "App Icons", isSelected: selectedCategory == .appIcon) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedCategory = .appIcon
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 16)
                    }
                    
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(filteredItems) { item in
                                ShopItemCard(
                                    item: item,
                                    isOwned: viewModel.owns(item: item),
                                    canAfford: viewModel.currentUser.points >= item.cost
                                ) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        viewModel.purchase(item: item)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)

                        Spacer().frame(height: 120)
                    }
                }
            }
            .navigationTitle("Store")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}


struct CategoryPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(isSelected ? Color.mint : Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(20)
               
                .shadow(color: isSelected ? .clear : Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
        }
    }
}

#Preview {
    ShopView(viewModel: ShopViewModel(currentUser: User(
        id: "1",
        username: "Kenjo", friendCode: "ROAM-0F0K",
        points: 100,
        currentStreak: 100,
        dailyStepTarget: 500,
        friendList: [],
        pendingFriendRequests: [],
        unlockedCustomizations: []
            )
        )
    )
}
