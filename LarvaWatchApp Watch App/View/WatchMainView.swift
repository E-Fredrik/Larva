//
//  WatchMainView.swift
//  LarvaWatchApp Watch App
//
//  Created by Elifele Fredrik on 28/05/26.
//

import SwiftUI

struct WatchMainView: View {
    @StateObject private var vm = WatchStepTrackerViewModel()

    var body: some View {
        VStack(spacing: 15) {
            if vm.session.isRunning {
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
            vm.requestPermissions()
            _ = WatchConnectivityManager.shared
        }
    }
}

#Preview {
    WatchMainView()
}
