//
//  WorkoutStats.swift
//  Larva
//
//  Created by Elifele Fredrik on 28/05/26.
//

import SwiftUI

/// A small metric display tile used inside `WorkoutControlPanel` to show a single
/// real-time workout statistic (Steps, Distance, or Pace).
///
/// Uses a monospaced font for the value so that digits don't shift as numbers change.
struct WorkoutStats: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(title)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            Text(value)
                .font(.system(.headline, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    WorkoutStats(title: "Time", value: "00:00:00")
}
