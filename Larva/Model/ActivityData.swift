//
//  ActivityData.swift
//  LarvaLawas
//
//  Created by Eko Nur Cahyo S on 27/05/26.
//

import Foundation

/// A snapshot of a user's physical activity for a single day.
/// Instances are keyed by ISO date strings ("yyyy-MM-dd") inside the
/// `dailyActivity` map on the `User` model and in Firebase.
struct ActivityData: Codable {
    /// Total step count recorded for the day.
    var steps: Int
    /// Estimated kilocalories burned (calculated as `steps * 0.04`).
    var caloriesBurned: Double
    /// Estimated distance covered in metres (calculated as `steps * 0.762`).
    var distanceInMeters: Double
    /// The date this record corresponds to (typically set to the start of the day).
    var date: Date
}
