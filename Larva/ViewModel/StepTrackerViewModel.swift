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

protocol StepTrackerDatabaseService {
    func fetchDailyTarget(userId: String) async throws -> Int?
    func saveWorkoutHistory(
        userId: String,
        sessionId: String,
        session: WorkoutData
    ) async throws
    func syncDailyActivity(
        userId: String,
        dateString: String,
        activity: ActivityData
    ) async throws
}

struct FirebaseStepTrackerDatabase: StepTrackerDatabaseService {
    private let dbRef = Database.database().reference()

    func fetchDailyTarget(userId: String) async throws -> Int? {
        let snapshot = try await dbRef.child("users").child(userId).child(
            "dailyStepTarget"
        ).getData()
        return snapshot.value as? Int
    }

    func saveWorkoutHistory(
        userId: String,
        sessionId: String,
        session: WorkoutData
    ) async throws {
        try dbRef.child("users").child(userId).child("workoutHistory").child(
            sessionId
        ).setValue(from: session)
    }

    func syncDailyActivity(
        userId: String,
        dateString: String,
        activity: ActivityData
    ) async throws {
        try dbRef.child("users").child(userId).child("dailyActivity").child(
            dateString
        ).setValue(from: activity)
    }
}

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
    private var cancellables = Set<AnyCancellable>()

    // Tracks the steps taken before a workout starts to keep the daily total accurate
    private var dailyBaselineBeforeWorkout: Int = 0
    private var currentSessionId: String = ""

    // Helper to get the current logged-in user ID safely
    private var currentUserId: String {
        Auth.auth().currentUser?.uid ?? "guest"
    }

    private var lastTrackedDateString: String {
        get { UserDefaults.standard.string(forKey: "\(currentUserId)_lastTrackedDateString") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "\(currentUserId)_lastTrackedDateString") }
    }

    private var lastRewardedPassiveSteps: Int {
        get { UserDefaults.standard.integer(forKey: "\(currentUserId)_lastRewardedPassiveSteps") }
        set { UserDefaults.standard.set(newValue, forKey: "\(currentUserId)_lastRewardedPassiveSteps") }
    }

    private var hasRewardedDailyGoal: Bool {
        get { UserDefaults.standard.bool(forKey: "\(currentUserId)_hasRewardedDailyGoal") }
        set { UserDefaults.standard.set(newValue, forKey: "\(currentUserId)_hasRewardedDailyGoal") }
    }

    init() {
        self.session = WorkoutData(
            steps: 0,
            distanceInMeters: 0.0,
            currentPace: 0.0,
            startDate: Date(),
            isRunning: false,
            route: []
        )

        // Listen for midnight rollovers
        NotificationCenter.default.publisher(for: .NSCalendarDayChanged)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.startPassiveTracking()
            }.store(in: &cancellables)

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
    
    private func checkAndResetNewDay() -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let currentDateString = formatter.string(from: Date())
        
        // If the date string doesn't match, a new day has started for this user
        if lastTrackedDateString != currentDateString {
            lastRewardedPassiveSteps = 0
            hasRewardedDailyGoal = false
            dailySteps = 0
            lastTrackedDateString = currentDateString
            return true
        }
        return false
    }

    func fetchUserDailyTarget() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        do {
            let snapshot = try await dbRef.child("users").child(userId).child(
                "dailyStepTarget"
            ).getData()
            if let target = snapshot.value as? Int {
                self.dailyTarget = target
            } else {
                self.dailyTarget = 5000 // Reset to clean default if new user has no record
            }
        } catch {
            print("Failed to fetch target, using default.")
            self.dailyTarget = 5000
        }
    }

    func startPassiveTracking() {
        guard CMPedometer.isStepCountingAvailable() else { return }

        // 1. Check if the day changed before we start tracking
        _ = checkAndResetNewDay()

        let today = Date()
        let midnight = Calendar.current.startOfDay(for: today)

        // 2. Stop any old updates so we don't get double callbacks
        passivePedometer.stopUpdates()

        // Makes sure we get the total steps for the day right away
        passivePedometer.queryPedometerData(from: midnight, to: today) {
            [weak self] data, error in
            if let data = data, error == nil {
                Task { @MainActor in
                    self?.dailySteps = data.numberOfSteps.intValue
                    await self?.syncDailyStepsToFirebase()
                }
            }
        }

        passivePedometer.startUpdates(from: midnight) {
            [weak self] data, error in
            guard let self = self, let data = data, error == nil else { return }

            Task { @MainActor in
                // 3. Catch day changes that happen while updates stream in the background
                if self.checkAndResetNewDay() {
                    self.startPassiveTracking() // Restart with the new midnight
                    return
                }

                self.dailySteps = data.numberOfSteps.intValue

                // Trigger the background points check automatically
                await self.syncDailyStepsToFirebase()
            }
        }
    }

    func toggleWorkoutSession() {
        if session.isRunning {
            stopActiveWorkout(isRemoteCommand: false)
        } else {
            startActiveWorkout(isRemoteCommand: false)
        }
    }

    private func startActiveWorkout(isRemoteCommand: Bool = false) {
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

        if !isRemoteCommand {
            WatchConnectivityManager.shared.sendWorkoutState(isRunning: true)
        }

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
        self.currentSessionId = "SESSION-\(UUID().uuidString.prefix(8))"
    }

    private func stopActiveWorkout(isRemoteCommand: Bool = false) {
        activePedometer.stopUpdates()
        session.isRunning = false

        if !isRemoteCommand {
            WatchConnectivityManager.shared.sendWorkoutState(isRunning: false)
        }

        startPassiveTracking()
    }

    // Formats pace
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
            let roundedMeters = session.distanceInMeters.rounded()
            return String(format: "%.0f m", roundedMeters)
        }
    }

    func attachRouteToSession(_ route: [RouteCoordinate]) {
        self.session.route = route

        // Trigger the database saves automatically when the session map finishes
        Task {
            await awardActiveWorkoutPoints()
            await saveWorkoutToFirebase()
            await syncDailyStepsToFirebase()
        }
    }

    private func awardActiveWorkoutPoints() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let activeSteps = self.session.steps
        guard activeSteps > 0 else { return }

        let pace = self.session.currentPace
        let speed = pace > 0 ? (1.0 / pace) : 1.0

        var paceMultiplier = 1.0
        if speed >= 2.5 {
            paceMultiplier = 2.0
        } else if speed >= 1.5 {
            paceMultiplier = 1.5
        }

        let basePoints = Double(activeSteps) / 20.0
        let totalActivePoints = Int(basePoints * paceMultiplier)

        guard totalActivePoints > 0 else { return }

        do {
            try await dbRef.child("users").child(userId).child("points")
                .setValue(
                    ServerValue.increment(NSNumber(value: totalActivePoints))
                )
            print(
                "🔥 Awarded \(totalActivePoints) Active Points! (Multiplier: \(paceMultiplier)x)"
            )
        } catch {
            print(
                "Failed to award active points: \(error.localizedDescription)"
            )
        }
    }

    private func saveWorkoutToFirebase() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let sessionId =
            self.currentSessionId.isEmpty
            ? "SESSION-\(UUID().uuidString.prefix(8))" : self.currentSessionId

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

        let unrewardedSteps = self.dailySteps - self.lastRewardedPassiveSteps

        if unrewardedSteps >= 100 {
            var pointsToAward = unrewardedSteps / 100

            if self.dailySteps >= self.dailyTarget && !self.hasRewardedDailyGoal
                && self.dailyTarget > 0
            {
                pointsToAward += 250
                self.hasRewardedDailyGoal = true
                print(
                    "🌟 \(self.dailyTarget) Daily Target Reached! 250 Bonus points awarded!"
                )
            }

            do {
                try await dbRef.child("users").child(userId).child("points")
                    .setValue(
                        ServerValue.increment(NSNumber(value: pointsToAward))
                    )

                self.lastRewardedPassiveSteps += (pointsToAward * 100)
                print("🚶‍♂️ Awarded \(pointsToAward) Passive Points!")
            } catch {
                print(
                    "Failed to sync passive points: \(error.localizedDescription)"
                )
            }
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: Date())

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
