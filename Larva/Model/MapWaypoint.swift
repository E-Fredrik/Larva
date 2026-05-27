//
//  MapWaypoint.swift
//  LarvaLawas
//
//  Created by Eko Nur Cahyo S on 27/05/26.
//

import Foundation
import CoreLocation

struct MapWaypoint: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let rewardPoints: Int
    var isClaimed: Bool = false
}
