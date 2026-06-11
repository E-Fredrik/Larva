//
//  WorkoutDetailView.swift
//  Larva
//
//  Created by Elifele Fredrik on 11/06/26.
//

import CoreLocation
import SwiftUI
import MapKit

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
