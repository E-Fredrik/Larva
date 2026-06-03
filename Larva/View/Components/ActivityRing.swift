//
//  ActivityRing.swift
//  Larva
//
//  Created by Elifele Fredrik on 28/05/26.
//

import SwiftUI

/// A circular progress ring drawn using two overlaid `Circle` strokes.
///
/// The background ring is always visible at low opacity; the foreground arc is
/// trimmed to represent `progress` (0.0 – 1.0) and animates with a spring effect.
/// Used inside `DailyStepsCard` to show daily step goal progress.
struct ActivityRing: View {
    /// A value between 0.0 (no progress) and 1.0 (full circle). Values above 1.0 are clamped.
    let progress: Double
    /// The colour applied to both the track (at 20 % opacity) and the filled arc.
    let color: Color

    var body: some View {
        ZStack {
            // Dim background ring showing the full circumference
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 8)

            // Foreground arc trimmed proportionally to `progress`
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90)) // Start at the top of the circle
                .animation(.spring(), value: progress)
        }
    }
}

#Preview {
    ActivityRing(progress: 50.0, color: .red)
}
