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

struct WorkoutStat: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 4) {
                Image(systemName: icon).foregroundColor(color).font(.caption)
                Text(title).font(.caption).foregroundColor(.secondary)
            }
            Text(value).font(.headline).fontWeight(.bold)
        }
    }
}

struct WorkoutDetailView: View {
    let session: WorkoutData
    @EnvironmentObject var profileVM: ProfileViewModel

    var mapRoute: [CLLocationCoordinate2D] {
        session.route.map { $0.asCLLocationCoordinate }
    }

    var body: some View {
        VStack(spacing: 0) {
            if mapRoute.isEmpty {
                Rectangle()
                    .fill(Color(UIColor.secondarySystemBackground))
                    .overlay(
                        Text("No GPS route recorded").foregroundColor(
                            .secondary
                        )
                    )
                    .frame(height: 300)
            } else {
                if #available(iOS 17.0, *) {
                    Map {
                        MapPolyline(coordinates: mapRoute)
                            .stroke(profileVM.currentAppTint, lineWidth: 5)
                    }
                    .frame(height: 300)
                } else {
                    Text("Requires iOS 17 for Map Polyline plotting.")
                        .frame(height: 300)
                        .background(Color(UIColor.secondarySystemBackground))
                }
            }

            List {
                Section("Workout Stats") {
                    HStack {
                        Text("Total Distance")
                        Spacer()
                        Text(
                            String(
                                format: "%.2f km",
                                session.distanceInMeters / 1000
                            )
                        ).bold()
                    }
                    HStack {
                        Text("Total Steps")
                        Spacer()
                        Text("\(session.steps)").bold()
                    }
                    HStack {
                        Text("Average Pace")
                        Spacer()
                        let secondsPerKm = session.currentPace * 1000
                        let minutes = Int(secondsPerKm) / 60
                        let seconds = Int(secondsPerKm) % 60
                        Text(String(format: "%d:%02d /km", minutes, seconds))
                            .bold()
                    }
                }
            }
        }
        .navigationTitle("Workout Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
