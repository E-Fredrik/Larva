//
//  LocationManager.swift
//  LarvaLawas
//
//  Created by Eko Nur Cahyo S on 27/05/26.
//

import Foundation
import CoreLocation
import Combine
import MapKit
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    private var manager = CLLocationManager()
    
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -7.2504, longitude: 112.7688),
        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
    )
    
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
            self.region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            )
            
            self.checkWaypointArrival(userLocation: location)
        }
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
                //Connect to model and view model
            }
        }
    }
}

