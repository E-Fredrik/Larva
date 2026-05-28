//
//  LocationManager.swift
//  LarvaLawas
//
//  Created by Eko Nur Cahyo S on 27/05/26.
//

import Foundation
import CoreLocation
import MapKit
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    private var manager = CLLocationManager()
    
    // Track raw location so we know where the user is without forcing the map to snap
    @Published var userLocation: CLLocation?
    
    // Navigation Data
    @Published var route: MKRoute?
    @Published var destinationCoordinate: CLLocationCoordinate2D?
    
    @Published var waypoints: [MapWaypoint] = [
        MapWaypoint(name: "Apple Infinite Loop", coordinate: CLLocationCoordinate2D(latitude: 37.3308, longitude: -122.0315), rewardPoints: 50),
        MapWaypoint(name: "De Anza Blvd", coordinate: CLLocationCoordinate2D(latitude: 37.3325, longitude: -122.0305), rewardPoints: 100),
        MapWaypoint(name: "Campus Gate", coordinate: CLLocationCoordinate2D(latitude: -7.2515, longitude: 112.7690), rewardPoints: 50),
        MapWaypoint(name: "Coffee Shop", coordinate: CLLocationCoordinate2D(latitude: -7.2490, longitude: 112.7680), rewardPoints: 100)
    ]
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            // We just store the location. We DON'T aggressively overwrite the map region here anymore.
            self.userLocation = location
            self.checkWaypointArrival(userLocation: location)
        }
    }
    
    // MARK: - Routing Logic
    func calculateWalkingRoute(to destination: CLLocationCoordinate2D) {
        guard let userLocation = userLocation else { return }
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .walking // Set to walking routes
        
        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, error in
            guard let route = response?.routes.first else {
                print("Failed to get route: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            DispatchQueue.main.async {
                self?.route = route
                self?.destinationCoordinate = destination
            }
        }
    }
    
    func clearRoute() {
        self.route = nil
        self.destinationCoordinate = nil
    }
    
    private func checkWaypointArrival(userLocation: CLLocation) {
        let captureRadiusInMeters: CLLocationDistance = 50.0
        
        for index in waypoints.indices {
            let waypoint = waypoints[index]
            
            if waypoint.isClaimed { continue }
            
            let poiLocation = CLLocation(latitude: waypoint.coordinate.latitude, longitude: waypoint.coordinate.longitude)
            let distance = userLocation.distance(from: poiLocation)
            if distance <= captureRadiusInMeters {
                waypoints[index].isClaimed = true
                print("🎉 Arrived at \(waypoint.name)! Awarded \(waypoint.rewardPoints) points.")
                // Connect to model and view model
            }
        }
    }
}
