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
        case .appTheme: return "paintpalette.fill"
        case .avatarBorder: return "person.crop.circle"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                ZStack {
                    Circle()
                        .fill(isOwned ? Color.mint.opacity(0.2) : Color.mint.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: iconName)
                        .font(.title3)
                        .foregroundColor(isOwned ? .mint : .mint.opacity(0.8))
                }
                
                Spacer()
                
                if isOwned {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.mint)
                        .font(.title3)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(1)
                
                Text(item.itemType.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer(minLength: 8)
            
            if isOwned {
                Text("Owned")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.mint)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.mint.opacity(0.1))
                    .cornerRadius(10)
            } else {
                Button(action: purchaseAction) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                        Text("\(item.cost)")
                            .fontWeight(.bold)
                    }
                    .foregroundColor(canAfford ? .white : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(canAfford ? Color.mint : Color.secondary.opacity(0.2))
                    .cornerRadius(10)
                }
                .disabled(!canAfford)
            }
        }
        .padding(16)
        .frame(height: 190)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isOwned ? Color.mint.opacity(0.5) : Color.clear, lineWidth: 2)
        )
    }
}
