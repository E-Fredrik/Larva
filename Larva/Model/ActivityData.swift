//
//  ActivityData.swift
//  LarvaLawas
//
//  Created by Eko Nur Cahyo S on 27/05/26.
//

import Foundation

struct ActivityData: Codable {
    var steps: Int
    var caloriesBurned: Double
    var distanceInMeters: Double
    var date: Date
}
