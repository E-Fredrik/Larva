//
//  LocationManager.swift
//  LarvaLawas
//

import Combine
import CoreLocation
import Foundation
import MapKit
import FirebaseDatabase
import FirebaseAuth

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    private var manager = CLLocationManager()
    private var dbRef = Database.database().reference()
    
    private var currentUserId: String? {
        return Auth.auth().currentUser?.uid
    }
    
    @Published var userLocation: CLLocation?
    @Published var route: MKRoute?
    @Published var destinationCoordinate: CLLocationCoordinate2D?
    
    @Published var workoutRoute: [CLLocationCoordinate2D] = []
    private var isRecordingWorkout: Bool = false
    
    @Published var waypoints: [MapWaypoint] = []
    
    private var allGlobalWaypoints: [MapWaypoint] = []
    private var userClaimedIDs: Set<String> = []
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        
        fetchDataStreams()
    }
    
    private func fetchDataStreams() {
        dbRef.child("waypoints").observe(.value) { [weak self] snapshot in
            guard let self = self else { return }
            var newWaypoints: [MapWaypoint] = []
            
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let dict = childSnapshot.value as? [String: Any],
                   let waypoint = MapWaypoint(id: childSnapshot.key, dictionary: dict) {
                    newWaypoints.append(waypoint)
                }
            }
            
            self.allGlobalWaypoints = newWaypoints
            self.mergeWaypointData()
        }
        
        if let userId = currentUserId {
            dbRef.child("users").child(userId).child("claimedWaypoints").observe(.value) { [weak self] snapshot in
                guard let self = self else { return }
                var claimedIDs = Set<String>()
                
                for child in snapshot.children {
                    if let childSnapshot = child as? DataSnapshot,
                       let isClaimed = childSnapshot.value as? Bool, isClaimed == true {
                        claimedIDs.insert(childSnapshot.key)
                    }
                }
                self.userClaimedIDs = claimedIDs
                self.mergeWaypointData()
            }
        }
    }
    
    private func mergeWaypointData() {
        var mergedWaypoints = allGlobalWaypoints
        for i in 0..<mergedWaypoints.count {
            if userClaimedIDs.contains(mergedWaypoints[i].id) {
                mergedWaypoints[i].isClaimed = true
            }
        }
        DispatchQueue.main.async {
            self.waypoints = mergedWaypoints
        }
    }
    
    private func markWaypointAsClaimedInFirebase(waypointId: String, rewardPoints: Int) {
        guard let userId = currentUserId else {
            print("Error: No user logged in to claim waypoint")
            return
        }
        
        dbRef.child("users").child(userId).child("claimedWaypoints").updateChildValues([
            waypointId: true
        ])
        
        let userPointsRef = dbRef.child("users").child(userId).child("points")
        userPointsRef.runTransactionBlock { (currentData: MutableData) -> TransactionResult in
            var points = currentData.value as? Int ?? 0
            points += rewardPoints
            currentData.value = points
            return TransactionResult.success(withValue: currentData)
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.last else { return }

        DispatchQueue.main.async {
            self.userLocation = location
            self.checkWaypointArrival(userLocation: location)

            
            if self.isRecordingWorkout {
                self.workoutRoute.append(location.coordinate)
            }
        }
    }

    func startRecordingWorkout() {
        workoutRoute.removeAll()
        isRecordingWorkout = true
    }

    func stopRecordingWorkout() -> [RouteCoordinate] {
        isRecordingWorkout = false
        // Convert MapKit coordinates to our Firebase Codable struct
        return workoutRoute.map {
            RouteCoordinate(lat: $0.latitude, lng: $0.longitude)
        }
    }
    
    func calculateWalkingRoute(to destination: CLLocationCoordinate2D) {
        guard let userLocation = userLocation else { return }

        let request = MKDirections.Request()
        request.source = MKMapItem(
            placemark: MKPlacemark(coordinate: userLocation.coordinate)
        )
        request.destination = MKMapItem(
            placemark: MKPlacemark(coordinate: destination)
        )
        request.transportType = .walking  // Set to walking routes

        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, error in
            guard let route = response?.routes.first else {
                print(
                    "Failed to get route: \(error?.localizedDescription ?? "Unknown error")"
                )
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
        let captureRadiusInMeters: CLLocationDistance = 100.0
        
        for index in waypoints.indices {
            let waypoint = waypoints[index]

            if waypoint.isClaimed { continue }

            let poiLocation = CLLocation(
                latitude: waypoint.coordinate.latitude,
                longitude: waypoint.coordinate.longitude
            )
            let distance = userLocation.distance(from: poiLocation)
            
            if distance <= captureRadiusInMeters {
                print("🎉 Arrived at \(waypoint.name)! Awarded \(waypoint.rewardPoints) points.")
                
                markWaypointAsClaimedInFirebase(waypointId: waypoint.id, rewardPoints: waypoint.rewardPoints)
            }
        }
    }
}
