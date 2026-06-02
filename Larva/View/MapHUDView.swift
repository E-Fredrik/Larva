//
//  MapHUDView.swift
//  Larva
//
//  Created by Eko Nur Cahyo S on 27/05/26.
//

import Combine
import MapKit
import SwiftUI

struct MapHUDView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var stepTracker = StepTrackerViewModel()
    @EnvironmentObject var profileVM: ProfileViewModel

    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)

    var body: some View {
        ZStack {
            MapReader { proxy in
                Map(position: $position) {
                    UserAnnotation()

                    if let route = locationManager.route {
                        MapPolyline(route).stroke(.blue, lineWidth: 5)
                    }

                    if !locationManager.workoutRoute.isEmpty {
                        MapPolyline(coordinates: locationManager.workoutRoute)
                            .stroke(.orange, style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                    }

                    if let destCoord = locationManager.destinationCoordinate {
                        Annotation("Destination", coordinate: destCoord) {
                            Image(systemName: "mappin.circle.fill").font(.title).foregroundColor(.red).background(Circle().fill(.white))
                        }
                    }

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
        .onChange(of: stepTracker.session.isRunning) { oldValue, isRunning in
            if isRunning { locationManager.startRecordingWorkout() } else {
                locationManager.stopRecordingWorkout()
                let finalizedRoute = locationManager.workoutRoute.map { coord in RouteCoordinate(lat: coord.latitude, lng: coord.longitude) }
                stepTracker.attachRouteToSession(finalizedRoute)
            }
        }
        .onAppear {
            stepTracker.startPassiveTracking()
            Task { await stepTracker.fetchUserDailyTarget() }
        }
        .alert("Route Unavailable", isPresented: $locationManager.showRoutingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("We couldn't calculate a walking route to that location. It might be too far or unreachable on foot.")
        }
    }
}
