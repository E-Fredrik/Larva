//
//  MockStepTracker.swift
//  Larva
//
//  Created by Elifele Fredrik on 28/05/26.
//

import Foundation

/// A test-double implementation of `StepTrackerDatabaseService`.
///
/// Records all arguments passed to each method and allows the return value of
/// `fetchDailyTarget` to be configured via `returnedTarget`. Used in unit tests
/// to verify that `StepTrackerViewModel` calls the database service correctly
/// without hitting a real Firebase database.
class MockStepTrackerDatabase: StepTrackerDatabaseService {
    /// Records the `userId` passed to `fetchDailyTarget` so tests can assert it.
    var fetchTargetCalledWithId: String?
    /// Configures the value returned by `fetchDailyTarget`. `nil` simulates a missing node.
    var returnedTarget: Int?

    /// Records the `sessionId` passed to `saveWorkoutHistory`.
    var savedSessionId: String?
    /// Records the `WorkoutData` passed to `saveWorkoutHistory`.
    var savedWorkout: WorkoutData?

    /// Records the ISO date string passed to `syncDailyActivity`.
    var syncedDateString: String?
    /// Records the `ActivityData` passed to `syncDailyActivity`.
    var syncedActivity: ActivityData?

    func fetchDailyTarget(userId: String) async throws -> Int? {
        fetchTargetCalledWithId = userId
        return returnedTarget
    }

    func saveWorkoutHistory(userId: String, sessionId: String, session: WorkoutData) async throws {
        savedSessionId = sessionId
        savedWorkout = session
    }

    func syncDailyActivity(userId: String, dateString: String, activity: ActivityData) async throws {
        syncedDateString = dateString
        syncedActivity = activity
    }
}
