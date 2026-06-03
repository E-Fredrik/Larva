//
//  ShopView.swift
//  Larva
//
//  Created by student on 28/05/26.
//

import SwiftUI

/// The cosmetic item shop where users spend points to unlock app themes and avatar borders.
///
/// A segmented picker at the top filters items by category (`appTheme` or `avatarBorder`).
/// Each `ShopItemCard` receives owned/affordable state computed here from `ShopViewModel`,
/// and an overlay spinner covers the whole screen while a purchase is being processed.
struct ShopView: View {
    @ObservedObject var viewModel: ShopViewModel
    /// Tracks the currently displayed category tab.
    @State private var selectedCategory: ShopItem.ItemType = .appTheme

    /// Returns only the items that match the currently selected category tab.
    var filteredItems: [ShopItem] {
        return viewModel.availableItems.filter { $0.itemType == selectedCategory }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Text("Shop").font(.largeTitle).fontWeight(.bold)
                    Spacer()
                    HStack {
                        Image(systemName: "star.fill").foregroundColor(.yellow)
                        Text("\(viewModel.userPoints)").fontWeight(.bold).monospacedDigit()
                    }
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.2)).cornerRadius(16)
                }
                .padding()

                Picker("Category", selection: $selectedCategory) {
                    Text("App Themes").tag(ShopItem.ItemType.appTheme)
                    Text("Borders").tag(ShopItem.ItemType.avatarBorder)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal).padding(.bottom, 8)

                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage).font(.callout).foregroundColor(.red).padding()
                }

                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(filteredItems) { item in
                            ShopItemCard(
                                item: item,
                                isOwned: viewModel.unlockedCustomizations.contains(item.id),
                                canAfford: viewModel.userPoints >= item.cost,
                                purchaseAction: { Task { await viewModel.purchaseItem(item: item) } }
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
                            ProgressView().tint(.white)
                            Text("Processing...").foregroundColor(.white).fontWeight(.bold)
                        }
                        .padding(24).background(Color(UIColor.secondarySystemBackground).opacity(0.9)).cornerRadius(16)
                    }
                }
            }
        }
    }
}

#Preview {
    ShopView(viewModel: ShopViewModel())
}
