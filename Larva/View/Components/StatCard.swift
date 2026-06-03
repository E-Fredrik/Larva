//
//  StatCard.swift
//  Larva
//
//  Created by student on 28/05/26.
//

import SwiftUI

/// A compact stat tile used in the Friends screen to display a single user metric.
/// Identical in purpose to `StatBox` but uses smaller font sizes (`.title2` icon, `.title3` value)
/// to fit more cleanly into the friends detail grid.
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}

#Preview {
    StatCard(title: "Friend", value: "300", icon: "person.2.fill", color: .black)
}
