//
//  ShopItemCard.swift
//  Larva
//
//  Created by student on 28/05/26.
//

import SwiftUI

/// A card in the shop grid representing a single purchasable cosmetic item.
///
/// Three display states are possible:
///  - **Owned**: Shows a checkmark and a green "Owned" badge; purchase button is hidden.
///  - **Affordable**: Shows a star-and-price purchase button in the app tint colour.
///  - **Not affordable**: Shows the price in grey and disables the button.
///
/// `purchaseAction` is called by `ShopView` which delegates to `ShopViewModel.purchaseItem(_:)`.
struct ShopItemCard: View {
    let item: ShopItem
    /// Whether the current user already owns this item.
    let isOwned: Bool
    /// Whether the user has enough points to buy this item (`userPoints >= item.cost`).
    let canAfford: Bool
    let purchaseAction: () -> Void
    
    @EnvironmentObject var profileVM: ProfileViewModel
    
    /// Maps the item's `ItemType` to an SF Symbol icon shown in the card.
    private var iconName: String {
        switch item.itemType {
        case .appTheme: return "paintpalette.fill"
        case .avatarBorder: return "person.crop.circle"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                ZStack {
                    Circle()
                        .fill(isOwned ? profileVM.currentAppTint.opacity(0.2) : profileVM.currentAppTint.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: iconName)
                        .font(.title3)
                        .foregroundColor(isOwned ? profileVM.currentAppTint : profileVM.currentAppTint.opacity(0.8))
                }
                
                Spacer()
                
                if isOwned {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(profileVM.currentAppTint)
                        .font(.title3)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name).font(.headline).fontWeight(.bold).lineLimit(1)
                Text(item.itemType.rawValue.capitalized).font(.caption).foregroundColor(.secondary)
            }
            
            Spacer(minLength: 8)
            
            if isOwned {
                Text("Owned")
                    .font(.caption).fontWeight(.bold).foregroundColor(profileVM.currentAppTint)
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                    .background(profileVM.currentAppTint.opacity(0.1)).cornerRadius(10)
            } else {
                Button(action: purchaseAction) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill").font(.caption)
                        Text("\(item.cost)").fontWeight(.bold)
                    }
                    .foregroundColor(canAfford ? .white : .secondary)
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                    .background(canAfford ? profileVM.currentAppTint : Color.secondary.opacity(0.2))
                    .cornerRadius(10)
                }
                .disabled(!canAfford)
            }
        }
        .padding(16).frame(height: 190)
        .background(Color(UIColor.secondarySystemGroupedBackground)).cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isOwned ? profileVM.currentAppTint.opacity(0.5) : Color.clear, lineWidth: 2)
        )
    }
}
