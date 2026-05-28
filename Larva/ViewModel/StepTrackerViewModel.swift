//
//  StepTrackerViewModel.swift
//  Larva
//
//  Created by Elifele Fredrik on 28/05/26.
//

import Combine
import CoreMotion
import Foundation

@MainActor
class StepTrackerViewModel: ObservableObject {
    @Published private var dailySteps: Int = 0
    @Published private var session: WorkoutData

    private let passivePedometer = CMPedometer()
    private let activePedometer = CMPedometer()

    init() {
        self.session = WorkoutData(
            steps: 0,
            distanceInMeters: 0.0,
            currentPace: 0.0,
            startDate: Date(),
            isRunning: false
        )
    }

    func startPassiveTracking() {
        guard CMPedometer.isStepCountingAvailable() else { return }
        
        //Finds the start of the day so that it can start tracking for the current day
        let midnight = Calendar.current.startOfDay(for: Date())

        passivePedometer.startUpdates(from: midnight) {
            [weak self] data, error in
            guard let self = self, let data = data, error == nil else { return }

            Task { @MainActor in
                self.dailySteps = data.numberOfSteps.intValue
            }
        }
    }

    func toggleWorkoutSession() {
        if session.isRunning {
            stopActiveWorkout()
        } else {
            startActiveWorkout()
        }
    }

    private func startActiveWorkout() {
        guard CMPedometer.isStepCountingAvailable() else { return }

        session = WorkoutData(
            steps: 0,
            distanceInMeters: 0.0,
            currentPace: 0.0,
            startDate: Date(),
            isRunning: true
        )

        activePedometer.startUpdates(from: session.startDate) {
            [weak self] data, error in
            guard let self = self, let data = data, error == nil else { return }

            Task { @MainActor in
                self.session.steps = data.numberOfSteps.intValue
                self.session.distanceInMeters =
                    data.distance?.doubleValue ?? 0.0
                self.session.currentPace =
                    data.currentPace?.doubleValue ?? 0.0
            }
        }
    }

    private func stopActiveWorkout() {
        activePedometer.stopUpdates()
        session.isRunning = false

        let midnight = Calendar.current.startOfDay(for: Date())
        passivePedometer.queryPedometerData(from: midnight, to: Date()) {
            [weak self] data, _ in
            if let data = data {
                Task { @MainActor in
                    self?.dailySteps = data.numberOfSteps.intValue
                }
            }
        }
    }

    //Formats pace since apple natively saves it in seconds per meter, we want to display it as minutes per kilometer
    var formattedPace: String {
        guard session.currentPace > 0 else { return "0:00" }
        let secondsPerKm = session.currentPace * 1000
        let minutes = Int(secondsPerKm) / 60
        let seconds = Int(secondsPerKm) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var formattedDistance: String {
        if session.distanceInMeters >= 1000 {
            return String(format: "%.2f km", session.distanceInMeters / 1000)
        } else {
            return String(format: "%.0f m", session.distanceInMeters)
        }
    }
}
