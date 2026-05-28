//
//  WorkoutControlPanel.swift
//  Larva
//
//  Created by Elifele Fredrik on 28/05/26.
//

import SwiftUI

struct WorkoutControlPanel: View {
    let isRecording: Bool
    let steps: Int
    let distance: String
    let pace: String
    let onToggleAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            if isRecording {
                HStack(spacing: 32) {
                    VStack(alignment: .center) {
                        Text("Session Steps")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(steps)")
                            .font(.title3.monospacedDigit())
                            .fontWeight(.bold)
                    }
                    
                    VStack(alignment: .center) {
                        Text("Distance")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(distance)
                            .font(.title3.monospacedDigit())
                            .fontWeight(.bold)
                    }
                    
                    VStack(alignment: .center) {
                        Text("Current Pace")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(pace) /km")
                            .font(.title3.monospacedDigit())
                            .fontWeight(.bold)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    onToggleAction()
                }
            }) {
                HStack {
                    Image(systemName: isRecording ? "stop.fill" : "figure.run")
                    Text(isRecording ? "End Session" : "Start Active Tracking")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isRecording ? Color.red : Color.mint)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
}

#Preview {
    WorkoutControlPanel()
}
