//
//  ShopView.swift
//  Larva
//
//  Created by student on 28/05/26.
//

import SwiftUI

struct ShopView: View {
    @ObservedObject var viewModel: ShopViewModel
    @State private var selectedCategory: ShopItem.ItemType = .mapTheme

    var filteredItems: [ShopItem] {
        return viewModel.availableItems.filter { $0.itemType == selectedCategory }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // Header
                HStack {
                    Text("Shop")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                    
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        
                        Text("\(viewModel.userPoints)")
                            .fontWeight(.bold)
                            .monospacedDigit()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(16)
                }
                .padding()

                Picker("Category", selection: $selectedCategory) {
                    Text("Map Themes").tag(ShopItem.ItemType.mapTheme)
                    Text("Borders").tag(ShopItem.ItemType.avatarBorder)
                    Text("Icons").tag(ShopItem.ItemType.appIcon)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 8)

                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .font(.callout)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }

                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(filteredItems) { item in
                            ShopItemCard(
                                item: item,
                                isOwned: viewModel.unlockedCustomizations.contains(item.id),
                                canAfford: viewModel.userPoints >= item.cost,
                                purchaseAction: {
                                    Task {
                                        await viewModel.purchaseItem(item: item)
                                    }
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
            .overlay {
                if viewModel.isPurchasing {
                    ZStack {
                        Color.black.opacity(0.4).ignoresSafeArea()
                        VStack(spacing: 16) {
                            ProgressView()
                                .tint(.white)
                            Text("Processing...")
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                        }
                        .padding(24)
                        .background(Color(UIColor.secondarySystemBackground).opacity(0.9))
                        .cornerRadius(16)
                    }
                }
            }
        }
    }
}

#Preview {
    ShopView(viewModel: ShopViewModel())
}
