//
//  MapWaypoint.swift
//  LarvaLawas
//

import Foundation
import CoreLocation

/// Represents a physical point-of-interest on the map that the user can discover by walking within range.
///
/// Waypoints are stored in Firebase under `waypoints/<id>` as flat dictionaries.
/// When a user walks within 50 m of an unclaimed waypoint, `LocationManager` automatically
/// claims it and awards the associated `rewardPoints`.
struct MapWaypoint: Identifiable {
    let id: String
    /// Human-readable label shown as an annotation on the map (e.g. "City Park").
    let name: String
    /// Geographic position of the waypoint, used to place the map annotation and measure proximity.
    let coordinate: CLLocationCoordinate2D
    /// Points the user earns the first time they visit and claim this waypoint.
    let rewardPoints: Int
    /// Whether the currently logged-in user has already claimed this waypoint.
    /// Claimed waypoints have their map annotation hidden to avoid clutter.
    var isClaimed: Bool = false
    
    /// Failable initialiser that constructs a waypoint from a raw Firebase dictionary.
    /// Returns `nil` if any required field (name, latitude, longitude, rewardPoints) is missing.
    init?(id: String, dictionary: [String: Any]) {
        guard let name = dictionary["name"] as? String,
              let latitude = dictionary["latitude"] as? Double,
              let longitude = dictionary["longitude"] as? Double,
              let rewardPoints = dictionary["rewardPoints"] as? Int else {
            return nil
        }
        
        self.id = id
        self.name = name
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.rewardPoints = rewardPoints
        self.isClaimed = dictionary["isClaimed"] as? Bool ?? false
    }
    
    /// Standard programmatic initialiser used for tests and previews.
    init(id: String = UUID().uuidString, name: String, coordinate: CLLocationCoordinate2D, rewardPoints: Int, isClaimed: Bool = false) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
        self.rewardPoints = rewardPoints
        self.isClaimed = isClaimed
    }
}
