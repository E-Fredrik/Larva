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

@MainActor
class WatchStepTrackerViewModel: NSObject, ObservableObject,
    CLLocationManagerDelegate
{
    @Published var session: WorkoutData
    @Published var dailySteps: Int = 0

    private var cancellables = Set<AnyCancellable>()

    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?

    private let pedometer = CMPedometer()
    private let locationManager = CLLocationManager()
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

        // Init health kit so that apple watch does not suspend the app (making it stop working in the background)
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

        // Update pedometer based on the session data
        dailyBaselineBeforeWorkout = dailySteps
        session = WorkoutData(
            steps: 0,
            distanceInMeters: 0,
            currentPace: 0,
            startDate: Date(),
            isRunning: true,
            route: []
        )
        
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
        
        if !isRemoteCommand {
            WatchConnectivityManager.shared.sendWorkoutState(isRunning: false)
        }

        WatchConnectivityManager.shared.sendWorkoutState(isRunning: false)
        WatchConnectivityManager.shared.sendWorkoutToPhone(self.session)

    }

    //Using nonisolated here to avoid blocking the main thread with constant location updates, since the location manager can call this method very frequently and we don't want to risk UI freezes.
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
