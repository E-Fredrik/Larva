//
//  RouteCoordinate.swift
//  Larva
//
//  Created by Elifele Fredrik on 28/05/26.
//

import Foundation
import CoreLocation

/// A lightweight, `Codable` representation of a GPS coordinate.
///
/// `CLLocationCoordinate2D` cannot conform to `Codable` directly, so this
/// wrapper is used to encode/decode GPS route points when storing a workout
/// in Firebase or sending it over WatchConnectivity.
struct RouteCoordinate: Codable {
        let lat: Double
        let lng: Double
        
        
        /// Converts this coordinate back into `CLLocationCoordinate2D` for use
        /// with MapKit overlays (e.g. `MapPolyline`).
        var asCLLocationCoordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: lat, longitude: lng)
        }
    }
