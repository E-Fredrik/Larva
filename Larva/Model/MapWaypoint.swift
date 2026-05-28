//
//  MapWaypoint.swift
//  LarvaLawas
//

import Foundation
import CoreLocation

struct MapWaypoint: Identifiable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let rewardPoints: Int
    var isClaimed: Bool = false
    
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
    
    init(id: String = UUID().uuidString, name: String, coordinate: CLLocationCoordinate2D, rewardPoints: Int, isClaimed: Bool = false) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
        self.rewardPoints = rewardPoints
        self.isClaimed = isClaimed
    }
}
