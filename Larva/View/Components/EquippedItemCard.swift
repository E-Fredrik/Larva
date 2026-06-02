//
//  EquippedItemCard.swift
//  Larva
//
//  Created by student on 28/05/26.
//

import SwiftUI

struct EquippedItemCard: View {
    let item: ShopItem
    
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
