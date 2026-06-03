//
//  MapHUDView.swift
//  Larva
//
//  Created by Eko Nur Cahyo S on 27/05/26.
//

import Combine
import MapKit
import SwiftUI

/// The primary map screen of the app, combining interactive MapKit with workout tracking.
///
/// Layers three overlapping concerns:
///  1. **Map**: A full-screen `Map` with user location annotation, waypoint annotations,
///     a blue navigation polyline (from MapKit Directions), and an orange workout route polyline.
///  2. **HUD**: A `DailyStepsCard` at the top and a `WorkoutControlPanel` at the bottom
///     that float over the map to display stats and controls.
///  3. **Coordination**: An `onChange` observer syncs workout state changes between
///     `StepTrackerViewModel` (manages the session) and `LocationManager` (records the GPS route).
struct MapHUDView: View {
    /// Owns the GPS, waypoint, and routing logic for this screen.
    @StateObject private var locationManager = LocationManager()
    /// Owns the step count, workout session, and Firebase sync logic.
    @StateObject private var stepTracker = StepTrackerViewModel()
    @EnvironmentObject var profileVM: ProfileViewModel

    /// Camera position bound to the user's real-time location; falls back to automatic if unavailable.
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)

    var body: some View {
        ZStack {
            MapReader { proxy in
                Map(position: $position) {
                    UserAnnotation()

                    // Blue polyline: walking route calculated by MapKit Directions.
                    if let route = locationManager.route {
                        MapPolyline(route).stroke(.blue, lineWidth: 5)
                    }

                    // Orange polyline: GPS route recorded during the active workout.
                    if !locationManager.workoutRoute.isEmpty {
                        MapPolyline(coordinates: locationManager.workoutRoute)
                            .stroke(.orange, style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                    }

                    // Red pin placed at the navigation destination selected by the user.
                    if let destCoord = locationManager.destinationCoordinate {
                        Annotation("Destination", coordinate: destCoord) {
                            Image(systemName: "mappin.circle.fill").font(.title).foregroundColor(.red).background(Circle().fill(.white))
                        }
                    }

                    // Tinted dot annotations for each unclaimed waypoint in the database.
                    // Claimed waypoints are hidden to reduce clutter.
                    // Tapping a waypoint calculates a walking route to it.
                    ForEach(locationManager.waypoints) { waypoint in
                        Annotation(waypoint.name, coordinate: waypoint.coordinate) {
                            if !waypoint.isClaimed {
                                VStack {
                                    ZStack {
                                        Circle()
                                            .fill(profileVM.currentAppTint.opacity(0.3))
                                            .frame(width: 40, height: 40)

                                        Circle()
                                            .fill(profileVM.currentAppTint)
                                            .frame(width: 16, height: 16)
                                            .shadow(radius: 3)
                                    }
                                    Text(waypoint.name).font(.caption).fontWeight(.bold).padding(4).background(.thinMaterial).cornerRadius(8)
                                }
                                .onTapGesture {
                                    locationManager.calculateWalkingRoute(to: waypoint.coordinate)
                                }
                            }
                        }
                    }
                }
                // Allow tapping anywhere on the map to navigate to that point.
                .onTapGesture { tapLocation in
                    if let coordinate = proxy.convert(tapLocation, from: .local) {
                        locationManager.calculateWalkingRoute(to: coordinate)
                    }
                }
            }
            .ignoresSafeArea()
            .tint(profileVM.currentAppTint)
            .mapStyle(.standard(elevation: .realistic))

            VStack {
                DailyStepsCard(stepCount: stepTracker.dailySteps, targetSteps: stepTracker.dailyTarget).padding(.horizontal)
                Spacer()
                VStack(spacing: 12) {
                    HStack(alignment: .bottom) {
                        if locationManager.destinationCoordinate != nil {
                            Button(action: { withAnimation { locationManager.clearRoute() } }) {
                                Text("Cancel Navigation").font(.subheadline).fontWeight(.bold).foregroundColor(.white).padding(.vertical, 8).padding(.horizontal, 16).background(Color.red.opacity(0.9)).cornerRadius(20)
                            }
                        }
                        Spacer()
                        Button(action: {
                            withAnimation(.easeInOut) { position = .userLocation(fallback: .automatic) }
                        }) {
                            Image(systemName: "location.fill").font(.system(size: 16))
                                .foregroundColor(profileVM.currentAppTint)
                                .padding(12).background(.thickMaterial).clipShape(Circle())
                        }
                    }
                    .padding(.horizontal)
                    
                    WorkoutControlPanel(isRecording: stepTracker.session.isRunning, steps: stepTracker.session.steps, distance: stepTracker.formattedDistance, pace: stepTracker.formattedPace, onToggleAction: { stepTracker.toggleWorkoutSession() }).padding(.horizontal)
                }
                .padding(.bottom, 24)
            }
        }
        // When the workout session starts or stops, synchronise with LocationManager.
        // On stop: finalise the GPS route and attach it to the session for Firebase upload.
        .onChange(of: stepTracker.session.isRunning) { oldValue, isRunning in
            if isRunning { locationManager.startRecordingWorkout() } else {
                locationManager.stopRecordingWorkout()
                let finalizedRoute = locationManager.workoutRoute.map { coord in RouteCoordinate(lat: coord.latitude, lng: coord.longitude) }
                stepTracker.attachRouteToSession(finalizedRoute)
            }
        }
        .onAppear {
            // Start the continuous background step counter and load the user's daily target.
            stepTracker.startPassiveTracking()
            Task { await stepTracker.fetchUserDailyTarget() }
        }
        // Alert shown when MapKit Directions cannot find a walking route.
        .alert("Route Unavailable", isPresented: $locationManager.showRoutingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("We couldn't calculate a walking route to that location. It might be too far or unreachable on foot.")
        }
    }
}
