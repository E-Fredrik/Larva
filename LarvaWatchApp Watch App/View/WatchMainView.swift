//
//  WatchMainView.swift
//  LarvaWatchApp Watch App
//
//  Created by Elifele Fredrik on 28/05/26.
//

import SwiftUI

/// The main screen of the Apple Watch app.
///
/// Displays a workout toggle button and, when a session is running, shows
/// live step count and distance values sourced from `WatchStepTrackerViewModel`.
/// On appear it requests HealthKit and location permissions, and activates
/// `WatchConnectivityManager` to begin listening for remote start/stop commands from the iPhone.
struct WatchMainView: View {
    /// Drives all step, distance, and workout state data for this view.
    @StateObject private var vm = WatchStepTrackerViewModel()

    var body: some View {
        VStack(spacing: 15) {
            if vm.session.isRunning {
                // Active workout: show live step and distance counters.
                VStack {
                    Text("\(vm.session.steps)")
                        .font(
                            .system(size: 40, weight: .bold, design: .rounded)
                        )
                        .foregroundColor(.green)
                    Text("Steps")
                        .font(.caption)

                    Text(
                        String(
                            format: "%.2f km",
                            vm.session.distanceInMeters / 1000
                        )
                    )
                    .font(.headline)
                    .foregroundColor(.gray)
                }
            } else {
                // Idle: show the running figure icon as a visual prompt.
                Image(systemName: "figure.run.circle.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.orange)
            }

            Button(action: {
                vm.toggleWorkout()
            }) {
                Text(vm.session.isRunning ? "End Workout" : "Start Workout")
                    .fontWeight(.bold)
                    .foregroundColor(vm.session.isRunning ? .red : .green)
            }
        }
        .onAppear {
            // Request HealthKit and location permissions before the first workout.
            vm.requestPermissions()
            // Activate the WatchConnectivity session so the Watch can receive
            // remote start/stop signals from the iPhone companion app.
            _ = WatchConnectivityManager.shared
        }
    }
}

#Preview {
    WatchMainView()
}
