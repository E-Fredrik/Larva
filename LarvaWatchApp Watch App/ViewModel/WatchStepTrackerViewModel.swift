//
//  WatchStepTrackerViewModel.swift
//  LarvaWatchApp Watch App
//
//  Created by Elifele Fredrik on 28/05/26.
//

import Combine
import CoreLocation
import CoreMotion
import Foundation
import HealthKit

/// The Watch app's step tracker and workout session manager.
///
/// Key design choices:
///  - An `HKWorkoutSession` is started even though HealthKit data isn't used directly.
///    This prevents watchOS from suspending the app in the background, which would stop
///    `CMPedometer` and `CLLocationManager` from delivering updates.
///  - A Combine subscription on `WatchConnectivityManager.remoteWorkoutState` enables
///    the iPhone companion app to start or stop a workout on the Watch remotely.
///  - GPS coordinates are appended to `session.route` in real time so they can be sent
///    to the iPhone as part of the final `WorkoutData` payload.
@MainActor
class WatchStepTrackerViewModel: NSObject, ObservableObject,
    CLLocationManagerDelegate
{
    /// Live workout data updated continuously while a session is running.
    @Published var session: WorkoutData
    /// Total steps counted since midnight (passive background accumulation).
    @Published var dailySteps: Int = 0

    private var cancellables = Set<AnyCancellable>()

    private let healthStore = HKHealthStore()
    /// HKWorkoutSession keeps watchOS from suspending the app during a workout.
    private var workoutSession: HKWorkoutSession?

    private let pedometer = CMPedometer()
    private let locationManager = CLLocationManager()
    /// The passive step count captured just before a workout started,
    /// used to compute the running `dailySteps` total during an active session.
    private var dailyBaselineBeforeWorkout: Int = 0

    override init() {
        self.session = WorkoutData(
            steps: 0,
            distanceInMeters: 0,
            currentPace: 0,
            startDate: Date(),
            isRunning: false,
            route: []
        )
        super.init()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //        locationManager.allowsBackgroundLocationUpdates = true

        // Subscribe to remote workout state changes from the iPhone.
        // If the phone starts a workout, start one here too (and vice versa).
        WatchConnectivityManager.shared.$remoteWorkoutState
            .compactMap({ $0 })
            .receive(on: RunLoop.main)
            .sink { [weak self] isRunning in
                guard let self = self else { return }

                if self.session.isRunning != isRunning {
                    if isRunning {
                        self.startActiveWorkout(isRemoteCommand: true)
                    } else {
                        self.stopActiveWorkout(isRemoteCommand: true)
                    }
                }
            }.store(in: &cancellables)
    }

    /// Requests HealthKit authorisation to share workouts (which keeps the app alive in the
    /// background) and to read step counts. Then enables background location on success.
    func requestPermissions() {
        let typesToShare: Set = [HKObjectType.workoutType()]
        let typesToRead: Set = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!
        ]

        healthStore.requestAuthorization(
            toShare: typesToShare,
            read: typesToRead
        ) { success, _ in
            if success {
                self.locationManager.requestWhenInUseAuthorization()
                self.locationManager.allowsBackgroundLocationUpdates = true
            }
        }
    }

    /// Toggles between starting and stopping a workout session.
    /// `isRemoteCommand: true` is passed to prevent sending a redundant connectivity
    /// message back to the device that issued the command.
    func toggleWorkout() {
        if session.isRunning {
            stopActiveWorkout(isRemoteCommand: true)
        } else {
            startActiveWorkout(isRemoteCommand: true)
        }
    }

    private func startActiveWorkout(isRemoteCommand: Bool = false) {
        #if !targetEnvironment(simulator)
            guard CMPedometer.isStepCountingAvailable() else { return }
        #endif

        // Start an HKWorkoutSession so watchOS does not suspend this app
        // while running in the background during a workout.
        let config = HKWorkoutConfiguration()
        config.activityType = .running
        config.locationType = .outdoor

        do {
            workoutSession = try HKWorkoutSession(
                healthStore: healthStore,
                configuration: config
            )
            workoutSession?.startActivity(with: Date())
        } catch {
            print("Failed to start workout session: \(error)")

        }

        // Snapshot the current daily step count as the baseline so that
        // active steps are counted from zero, not from today's total.
        dailyBaselineBeforeWorkout = dailySteps
        session = WorkoutData(
            steps: 0,
            distanceInMeters: 0,
            currentPace: 0,
            startDate: Date(),
            isRunning: true,
            route: []
        )
        
        // Only notify the iPhone if this start was triggered locally on the Watch.
        if !isRemoteCommand {
            WatchConnectivityManager.shared.sendWorkoutState(isRunning: true)
        }

        locationManager.startUpdatingLocation()
        pedometer.startUpdates(from: session.startDate) {
            [weak self] data, error in
            guard let self = self, let data = data, error == nil else { return }
            Task { @MainActor in
                self.session.steps = data.numberOfSteps.intValue
                self.session.distanceInMeters = data.distance?.doubleValue ?? 0
                self.session.currentPace = data.currentPace?.doubleValue ?? 0
                self.dailySteps =
                    self.dailyBaselineBeforeWorkout + self.session.steps
            }
        }

        WatchConnectivityManager.shared.sendWorkoutState(isRunning: true)
    }

    private func stopActiveWorkout(isRemoteCommand: Bool = false) {
        workoutSession?.end()
        locationManager.stopUpdatingLocation()
        pedometer.stopUpdates()
        session.isRunning = false
        
        // Only notify the iPhone if this stop was triggered locally on the Watch.
        if !isRemoteCommand {
            WatchConnectivityManager.shared.sendWorkoutState(isRunning: false)
        }

        // Always send the full workout payload so the iPhone can persist the route.
        WatchConnectivityManager.shared.sendWorkoutState(isRunning: false)
        WatchConnectivityManager.shared.sendWorkoutToPhone(self.session)

    }

    /// Receives location updates off the main thread (`nonisolated`) to avoid UI freezes.
    /// Appends each coordinate to `session.route` only while a workout is running.
    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            if self.session.isRunning {
                let coord = RouteCoordinate(
                    lat: location.coordinate.latitude,
                    lng: location.coordinate.longitude
                )
                self.session.route.append(coord)
            }
        }
    }
}
