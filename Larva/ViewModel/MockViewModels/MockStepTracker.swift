//
//  MockStepTracker.swift
//  Larva
//
//  Created by Elifele Fredrik on 28/05/26.
//

import Foundation

class MockStepTrackerDatabase: StepTrackerDatabaseService {
    var fetchTargetCalledWithId: String?
    var returnedTarget: Int?

    var savedSessionId: String?
    var savedWorkout: WorkoutData?

    var syncedDateString: String?
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
