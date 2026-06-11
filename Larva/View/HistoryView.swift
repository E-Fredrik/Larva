//
//  HistoryView.swift
//  Larva
//
//  Created by Elifele Fredrik on 06/06/26.
//

import MapKit
import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: HistoryViewModel
    @EnvironmentObject var profileVM: ProfileViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading History...")
                } else if viewModel.pastWorkouts.isEmpty {
                    if #available(iOS 17.0, *) {
                        ContentUnavailableView(
                            "No Workouts Yet",
                            systemImage: "figure.walk",
                            description: Text(
                                "Start an active workout on your watch or phone to see your history here."
                            )
                        )
                    } else {
                        Text("No Workouts Yet").foregroundColor(.secondary)
                    }
                } else {
                    List(viewModel.pastWorkouts, id: \.startDate) { workout in
                        NavigationLink(
                            destination: WorkoutDetailView(session: workout)
                        ) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(
                                    workout.startDate.formatted(
                                        date: .abbreviated,
                                        time: .shortened
                                    )
                                )
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                                HStack(spacing: 24) {
                                    WorkoutStat(
                                        title: "Distance",
                                        value: String(
                                            format: "%.2f km",
                                            workout.distanceInMeters / 1000
                                        ),
                                        icon: "map.fill",
                                        color: profileVM.currentAppTint
                                    )
                                    WorkoutStat(
                                        title: "Steps",
                                        value: "\(workout.steps)",
                                        icon: "shoeprints.fill",
                                        color: profileVM.currentAppTint
                                    )
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("History")
            .onAppear {
                viewModel.startListeningForHistory(
                    userId: profileVM.currentUser.id
                )
            }
        }
    }
}


