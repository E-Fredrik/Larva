//
//  StepTrackerViewModel.swift
//  Larva
//
//  Created by Elifele Fredrik on 28/05/26.
//

import Combine
import CoreMotion
import FirebaseAuth
import FirebaseDatabase
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

    private let dbRef = Database.database().reference()

    // Tracks the steps taken before a workout starts to keep the daily total accurate
    private var dailyBaselineBeforeWorkout: Int = 0

    init() {
        self.session = WorkoutData(
            steps: 0,
            distanceInMeters: 0.0,
            currentPace: 0.0,
            startDate: Date(),
            isRunning: false,
            route: []
        )
    }

    func fetchUserDailyTarget() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        do {
            let snapshot = try await dbRef.child("users").child(userId).child(
                "dailyStepTarget"
            ).getData()
            if let target = snapshot.value as? Int {
                self.dailyTarget = target
            }
        } catch {
            print("Failed to fetch target, using default.")
        }
    }

    func startPassiveTracking() {
        guard CMPedometer.isStepCountingAvailable() else { return }

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
        #if !targetEnvironment(simulator)
            guard CMPedometer.isStepCountingAvailable() else { return }
        #endif

        dailyBaselineBeforeWorkout = dailySteps
        passivePedometer.stopUpdates()

        session = WorkoutData(
            steps: 0,
            distanceInMeters: 0.0,
            currentPace: 0.0,
            startDate: Date(),
            isRunning: true,
            route: []
        )

        activePedometer.startUpdates(from: session.startDate) {
            [weak self] data, error in
            guard let self = self, let data = data, error == nil else { return }

            Task { @MainActor in
                self.session.steps = data.numberOfSteps.intValue
                self.session.distanceInMeters =
                    data.distance?.doubleValue ?? 0.0
                self.session.currentPace = data.currentPace?.doubleValue ?? 0.0

                self.dailySteps =
                    self.dailyBaselineBeforeWorkout
                    + data.numberOfSteps.intValue
            }
        }
    }

    private func stopActiveWorkout() {

        activePedometer.stopUpdates()
        session.isRunning = false

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

    func attachRouteToSession(_ route: [RouteCoordinate]) {
        self.session.route = route

        // Trigger the database saves automatically when the session finishes
        Task {
            await saveWorkoutToFirebase()
            await syncDailyStepsToFirebase()
        }
    }

    private func saveWorkoutToFirebase() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let sessionId = "SESSION-\(UUID().uuidString.prefix(8))"

        do {
            try dbRef
                .child("users")
                .child(userId)
                .child("workoutHistory")
                .child(sessionId)
                .setValue(from: session)

            print("Successfully saved Active Workout to Firebase.")
        } catch {
            print("Failed to save workout: \(error.localizedDescription)")
        }
    }

    func syncDailyStepsToFirebase() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        // Use today's date as the document ID (e.g., "2026-05-28")
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: Date())

        // Re-use your ActivityData model for the push
        let activity = ActivityData(
            steps: dailySteps,
            caloriesBurned: Double(dailySteps) * 0.04,
            distanceInMeters: Double(dailySteps) * 0.762,
            date: Date()
        )

        do {
            try dbRef
                .child("users")
                .child(userId)
                .child("dailyActivity")
                .child(dateString)
                .setValue(from: activity)

            print(
                "Successfully synced \(dailySteps) total daily steps to Firebase."
            )
        } catch {
            print("Failed to sync daily steps: \(error.localizedDescription)")
        }
    }

    #if DEBUG
        /// Forces the view model into an active running state without needing hardware sensors
        func test_forceWorkoutState(isRunning: Bool) {
            self.session.isRunning = isRunning
        }

        /// Hardcodes step and distance data directly into the properties
        func test_injectMetrics(
            passiveSteps: Int,
            activeSteps: Int,
            distance: Double,
            pace: Double
        ) {
            self.dailySteps = passiveSteps + activeSteps
            self.session.steps = activeSteps
            self.session.distanceInMeters = distance
            self.session.currentPace = pace
        }

        /// Hardcodes the daily target without needing a Firebase fetch
        func test_setTarget(_ target: Int) {
            self.dailyTarget = target
        }
    #endif
}
