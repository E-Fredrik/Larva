//
//  WorkoutData.swift
//  Larva
//
//  Created by Elifele Fredrik on 28/05/26.
//

import Foundation

struct WorkoutData: Codable {
    var steps: Int
    var distanceInMeters: Double
    var currentPace: Double
    var startDate: Date
    var isRunning: Bool
    var route: [RouteCoordinate]
}
