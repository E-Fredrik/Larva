//
//  EquippedItemCard.swift
//  Larva
//
//  Created by student on 28/05/26.
//

import SwiftUI

/// Displays a single equipped cosmetic item (appTheme or avatarBorder) on the Profile screen.
///
/// Shows an icon chosen by `itemType`, the item's name, and its category label.
/// Used in a horizontal scroll row inside `ProfileView` to represent all currently equipped items.
struct EquippedItemCard: View {
    let item: ShopItem
    
    /// Maps the item's `ItemType` to an SF Symbol for the icon displayed in the card.
    private var iconName: String {
        switch item.itemType {
        case .appTheme: return "paintpalette.fill"
        case .avatarBorder: return "person.crop.circle"
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.primary.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: iconName)
                    .font(.title2)
            }
            
            Text(item.name)
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(1)
            
            Text(item.itemType.rawValue.capitalized)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .frame(width: 110)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}
