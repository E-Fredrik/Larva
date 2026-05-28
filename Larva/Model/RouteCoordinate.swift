//
//  RouteCoordinate.swift
//  Larva
//
//  Created by Elifele Fredrik on 28/05/26.
//

import Foundation
import CoreLocation

struct RouteCoordinate: Codable {
        let lat: Double
        let lng: Double
        
        
        var asCLLocationCoordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: lat, longitude: lng)
        }
    }
