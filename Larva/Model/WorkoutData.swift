//
//  WorkoutData.swift
//  Larva
//
//  Created by Elifele Fredrik on 28/05/26.
//

import Foundation

/// Captures the real-time state and final statistics of a single workout session.
///
/// This struct is passed between the Watch and iPhone via WatchConnectivity,
/// and is also persisted to Firebase under `users/<uid>/workoutHistory/<sessionId>`.
struct WorkoutData: Codable {
    /// Steps counted by `CMPedometer` during the session.
    var steps: Int
    /// Total distance covered in metres during the session.
    var distanceInMeters: Double
    /// Current walking/running pace in seconds-per-metre (as reported by `CMPedometer`).
    var currentPace: Double
    /// The timestamp when this workout session was started.
    var startDate: Date
    /// Whether the workout is currently active. Set to `false` when the session ends.
    var isRunning: Bool
    /// Ordered list of GPS coordinates recorded during the session, used to draw the route on the map.
    var route: [RouteCoordinate]
}
