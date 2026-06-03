//
//  MetricPill.swift
//  Larva
//
//  Created by student on 28/05/26.
//

import SwiftUI

/// A pill-shaped toggle button used as a filter selector on the leaderboard screen.
///
/// When `isSelected` is `true` the pill becomes filled with the accent colour and the
/// label switches to bold. Tapping the pill calls `action`, which the parent uses to
/// update the `selectedMetric` or `selectedTimeframe` state.
struct MetricPill: View {
    let title: String
    let icon: String
    /// Whether this pill represents the currently active filter option.
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .bold : .medium)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Color.mint : Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(20)
            .shadow(color: isSelected ? Color.mint.opacity(0.3) : Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}
