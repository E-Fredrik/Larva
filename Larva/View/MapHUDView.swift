//
//  MapHUDView.swift
//  LarvaLawas
//
//  Created by Eko Nur Cahyo S on 27/05/26.
//

import Combine
import MapKit
import SwiftUI

struct MapHUDView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var stepTracker = StepTrackerViewModel()

    @State private var position: MapCameraPosition = .userLocation(
        fallback: .automatic
    )

    var body: some View {
        ZStack {
            MapReader { proxy in
                Map(position: $position) {
                    UserAnnotation()

                    if let route = locationManager.route {
                        MapPolyline(route)
                            .stroke(.blue, lineWidth: 5)
                    }

                    if !locationManager.workoutRoute.isEmpty {
                        MapPolyline(coordinates: locationManager.workoutRoute)
                            .stroke(
                                .orange,
                                style: StrokeStyle(
                                    lineWidth: 8,
                                    lineCap: .round,
                                    lineJoin: .round
                                )
                            )
                    }

                    if let destCoord = locationManager.destinationCoordinate {
                        Annotation("Destination", coordinate: destCoord) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title)
                                .foregroundColor(.red)
                                .background(Circle().fill(.white))
                        }
                    }

                    ForEach(locationManager.waypoints) { waypoint in
                        Annotation(
                            waypoint.name,
                            coordinate: waypoint.coordinate
                        ) {
                            if !waypoint.isClaimed {
                                VStack {
                                    ZStack {
                                        Circle()
                                            .fill(Color.mint.opacity(0.3))
                                            .frame(width: 40, height: 40)

                                        Circle()
                                            .fill(Color.mint)
                                            .frame(width: 16, height: 16)
                                            .shadow(radius: 3)
                                    }
                                    Text(waypoint.name)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .padding(4)
                                        .background(.thinMaterial)
                                        .cornerRadius(8)
                                }
                                .onTapGesture {
                                    locationManager.calculateWalkingRoute(
                                        to: waypoint.coordinate
                                    )
                                }
                            }
                        }
                    }
                }
                .onTapGesture { tapLocation in
                    if let coordinate = proxy.convert(tapLocation, from: .local)
                    {
                        locationManager.calculateWalkingRoute(to: coordinate)
                    }
                }
            }
            .ignoresSafeArea()
            .tint(.mint)
            .mapStyle(.standard(elevation: .realistic))

            // HUD
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Steps: 4")
                            .font(.headline)
                        Text("Distance: 20m")
                            .font(.subheadline)
                    }
                    Spacer()
                }
                .padding()
                .background(.thinMaterial)
                .cornerRadius(16)
                .padding()

                DailyStepsCard(
                    stepCount: stepTracker.dailySteps,
                    targetSteps: stepTracker.dailyTarget,
                )
                .padding(.horizontal)

                Spacer()

                VStack(spacing: 12) {
                    HStack(alignment: .bottom) {
                        if locationManager.route != nil {
                            Button(action: {
                                withAnimation {
                                    locationManager.clearRoute()
                                }
                            }) {
                                Text("Cancel Navigation")
                                    .font(.subheadline).fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 8).padding(
                                        .horizontal,
                                        16
                                    )
                                    .background(Color.red.opacity(0.9))
                                    .cornerRadius(20)
                            }
                        }
                        Spacer()

                        Button(action: {
                            withAnimation(.easeInOut) {
                                position = .userLocation(fallback: .automatic)
                            }
                        }) {
                            Image(systemName: "location.fill").font(
                                .system(size: 16)
                            ).foregroundColor(.mint)
                                .padding(12).background(.thickMaterial)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal)

                    WorkoutControlPanel(
                        isRecording: stepTracker.session.isRunning,
                        steps: stepTracker.session.steps,
                        distance: stepTracker.formattedDistance,
                        pace: stepTracker.formattedPace,
                        onToggleAction: {
                            stepTracker.toggleWorkoutSession()
                        }
                    )
                    .padding(.horizontal)
                }
                .padding(.bottom, 24)
            }
        }
        .onChange(of: stepTracker.session.isRunning) { oldValue, isRunning in
            if isRunning {
                locationManager.startRecordingWorkout()
            } else {
                let finalizedRoute = locationManager.stopRecordingWorkout()

                stepTracker.attachRouteToSession(finalizedRoute)

                print(
                    "Workout saved with \(finalizedRoute.count) location points."
                )
            }
        }
    }
}

struct MapHUDView_Previews: PreviewProvider {
    static var previews: some View {
        MapHUDView()
            .previewDevice(PreviewDevice(rawValue: "iPhone 14 Pro"))
            .preferredColorScheme(.dark)
    }
}
