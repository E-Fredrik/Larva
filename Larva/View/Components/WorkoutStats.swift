//
//  WorkoutStats.swift
//  Larva
//
//  Created by Elifele Fredrik on 28/05/26.
//

import SwiftUI

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
