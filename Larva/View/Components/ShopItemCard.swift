//
//  ShopItemCard.swift
//  Larva
//
//  Created by student on 28/05/26.
//

import SwiftUI

struct ShopItemCard: View {
    let item: ShopItem
    let isOwned: Bool
    let canAfford: Bool
    let purchaseAction: () -> Void
    
    private var iconName: String {
        switch item.itemType {
        case .mapTheme: return "map.fill"
        case .avatarBorder: return "person.crop.circle"
        case .appIcon: return "app.dashed"
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isOwned ? Color.mint.opacity(0.2) : Color.secondary.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: iconName)
                    .font(.title)
                    .foregroundColor(isOwned ? .mint : .primary)
            }
            .padding(.top, 12)
            
            VStack(spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                
                Text(item.itemType.rawValue.capitalized)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer(minLength: 0)
            
            if isOwned {
                Text("Owned")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.mint)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color.mint.opacity(0.1))
                    .cornerRadius(8)
            } else {
                Button(action: purchaseAction) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                        // Reads from your 'cost' property
                        Text("\(item.cost)")
                            .fontWeight(.bold)
                    }
                    .foregroundColor(canAfford ? .white : .secondary)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(canAfford ? Color.mint : Color.secondary.opacity(0.2))
                    .cornerRadius(8)
                }
                .disabled(!canAfford)
            }
        }
        .padding(12)
        .frame(height: 200)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isOwned ? Color.mint : Color.clear, lineWidth: 2)
        )
    }
}
