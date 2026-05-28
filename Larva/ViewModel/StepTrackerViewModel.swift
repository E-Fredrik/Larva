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
    @Published private(set) var dailySteps: Int = 0
    @Published var dailyTarget: Int = 5000
    @Published private(set) var session: WorkoutData

    var dailyProgress: Double {
        guard dailyTarget > 0 else { return 0.0 }
        return Double(dailySteps) / Double(dailyTarget)
    }

    private let passivePedometer = CMPedometer()
    private let activePedometer = CMPedometer()
    
    // Tracks the steps taken before a workout starts to keep the daily total accurate
    private var dailyBaselineBeforeWorkout: Int = 0

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

        let midnight = Calendar.current.startOfDay(for: Date())

        passivePedometer.startUpdates(from: midnight) { [weak self] data, error in
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

        // 1. Save current daily steps and STOP passive updates to free up the hardware sensor
        dailyBaselineBeforeWorkout = dailySteps
        passivePedometer.stopUpdates()

        // 2. Initialize the active session state
        session = WorkoutData(
            steps: 0,
            distanceInMeters: 0.0,
            currentPace: 0.0,
            startDate: Date(),
            isRunning: true
        )

        // 3. Start real-time updates specifically for the workout
        activePedometer.startUpdates(from: session.startDate) { [weak self] data, error in
            guard let self = self, let data = data, error == nil else { return }

            Task { @MainActor in
                // Update the active running stats
                self.session.steps = data.numberOfSteps.intValue
                self.session.distanceInMeters = data.distance?.doubleValue ?? 0.0
                self.session.currentPace = data.currentPace?.doubleValue ?? 0.0
                
                // Keep the overall daily target progressing while running
                self.dailySteps = self.dailyBaselineBeforeWorkout + data.numberOfSteps.intValue
            }
        }
    }

    private func stopActiveWorkout() {
        // 1. Stop the high-frequency active tracking
        activePedometer.stopUpdates()
        session.isRunning = false

        // 2. Restart the passive tracking to resume all-day background counting
        startPassiveTracking()
    }

    // Formats pace since apple natively saves it in seconds per meter, we want to display it as minutes per kilometer
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
