//
//  LeaderboardRow.swift
//  LarvaDep
//
//  Created by Eko Nur Cahyo S on 27/05/26.
//

import SwiftUI

struct LeaderboardRow: View {
    let user: User
    let rank: Int
    let metric: LeaderboardMetric
    let timeframe: LeaderboardTimeframe
    let isCurrentUser: Bool

    private var rankColor: Color {
        switch rank {
        case 1: return Color.yellow
        case 2: return Color(UIColor.lightGray)
        case 3: return Color.orange  // Bronze-ish
        default: return Color.secondary.opacity(0.5)
        }
    }

    private var displayValue: String {
        switch metric {
        case .streaks:
            return "\(user.currentStreak) Days"
        case .steps:
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            return formatter.string(
                from: NSNumber(value: user.mockSteps(for: timeframe))
            ) ?? "0"
        case .distance:
            return String(format: "%.1f km", user.mockDistance(for: timeframe))
        }
    }

    private var metricIcon: String {
        switch metric {
        case .streaks: return "flame.fill"
        case .steps: return "shoeprints.fill"
        case .distance: return "map.fill"
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(rank <= 3 ? rankColor.opacity(0.2) : Color.clear)
                    .frame(width: 36, height: 36)

                Text("\(rank)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(rank <= 3 ? rankColor : .secondary)
            }
            .frame(width: 40)

            Circle()
                .fill(Color.mint.opacity(0.2))
                .frame(width: 48, height: 48)
                .overlay(
                    Text(String(user.username.prefix(1)).uppercased())
                        .font(
                            .system(size: 20, weight: .bold, design: .rounded)
                        )
                        .foregroundColor(.mint)
                )
                .overlay(
                    Circle().stroke(
                        isCurrentUser ? Color.yellow : Color.clear,
                        lineWidth: 2
                    )
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(user.username)
                    .font(.headline)
                    .foregroundColor(isCurrentUser ? .primary : .primary)

                if isCurrentUser {
                    Text("You")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.mint)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.mint.opacity(0.2))
                        .cornerRadius(4)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: metricIcon)
                        .font(.caption)
                        .foregroundColor(metric == .streaks ? .orange : .mint)

                    Text(displayValue)
                        .font(.subheadline)
                        .fontWeight(.bold)
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(
            color: Color.black.opacity(isCurrentUser ? 0.08 : 0.03),
            radius: 8,
            x: 0,
            y: 4
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    isCurrentUser ? Color.yellow.opacity(0.6) : Color.clear,
                    lineWidth: 2
                )
        )
    }
}
