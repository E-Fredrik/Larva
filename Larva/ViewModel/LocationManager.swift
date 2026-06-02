//
//  LocationManager.swift
//  LarvaLawas
//

import Combine
import CoreLocation
import FirebaseAuth
import FirebaseDatabase
import Foundation
import MapKit

// Dependency Protocol

protocol LocationProviderProtocol: AnyObject {
    var delegate: CLLocationManagerDelegate? { get set }
    var desiredAccuracy: CLLocationAccuracy { get set }
    func requestWhenInUseAuthorization()
    func startUpdatingLocation()
}

extension CLLocationManager: LocationProviderProtocol {}

protocol WaypointDatabaseProtocol {
    func observeGlobalWaypoints(completion: @escaping ([MapWaypoint]) -> Void)
    func observeUserClaimedWaypoints(
        userId: String,
        completion: @escaping (Set<String>) -> Void
    )
    func claimWaypoint(userId: String, waypointId: String, rewardPoints: Int)
}

protocol AuthSessionProtocol {
    var currentUserId: String? { get }
}

protocol RoutingProviderProtocol {
    func calculateWalkingRoute(
        from source: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D
    ) async throws -> MKRoute?
}

// Production Implementation

// Real Firebase Auth Wrapper
struct FirebaseAuthSession: AuthSessionProtocol {
    var currentUserId: String? { Auth.auth().currentUser?.uid }
}

// Real Firebase Database Wrapper
struct FirebaseWaypointDatabase: WaypointDatabaseProtocol {
    private let dbRef = Database.database(url: "https://larvva-d2753-default-rtdb.asia-southeast1.firebasedatabase.app").reference()
    func observeGlobalWaypoints(completion: @escaping ([MapWaypoint]) -> Void) {
        dbRef.child("waypoints").observe(.value) { snapshot in
            var newWaypoints: [MapWaypoint] = []
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                    let dict = childSnapshot.value as? [String: Any],
                    let waypoint = MapWaypoint(
                        id: childSnapshot.key,
                        dictionary: dict
                    )
                {
                    newWaypoints.append(waypoint)
                }
            }
            completion(newWaypoints)
        }
    }

    func observeUserClaimedWaypoints(
        userId: String,
        completion: @escaping (Set<String>) -> Void
    ) {
        dbRef.child("users").child(userId).child("claimedWaypoints").observe(
            .value
        ) { snapshot in
            var claimedIDs = Set<String>()
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                    let isClaimed = childSnapshot.value as? Bool,
                    isClaimed == true
                {
                    claimedIDs.insert(childSnapshot.key)
                }
            }
            completion(claimedIDs)
        }
    }

    func claimWaypoint(userId: String, waypointId: String, rewardPoints: Int) {
        dbRef.child("users").child(userId).child("claimedWaypoints")
            .updateChildValues([waypointId: true])
        let userPointsRef = dbRef.child("users").child(userId).child("points")
        userPointsRef.runTransactionBlock {
            (currentData: MutableData) -> TransactionResult in
            var points = currentData.value as? Int ?? 0
            points += rewardPoints
            currentData.value = points
            return TransactionResult.success(withValue: currentData)
        }
    }
}

// Real Apple Routing Wrapper
struct AppleRoutingProvider: RoutingProviderProtocol {
    func calculateWalkingRoute(
        from source: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D
    ) async throws -> MKRoute? {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
        request.destination = MKMapItem(
            placemark: MKPlacemark(coordinate: destination)
        )
        request.transportType = .walking

        let directions = MKDirections(request: request)
        let response = try await directions.calculate()
        return response.routes.first
    }
}

//ViewModel
@MainActor
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    // Injected Dependencies
    private var locationProvider: LocationProviderProtocol
    private var dbService: WaypointDatabaseProtocol
    private var authSession: AuthSessionProtocol
    private var routingProvider: RoutingProviderProtocol

    @Published var userLocation: CLLocation?
    @Published var route: MKRoute?
    @Published var destinationCoordinate: CLLocationCoordinate2D?
    @Published var waypoints: [MapWaypoint] = []

    // Workout Tracking Properties
    @Published var workoutRoute: [CLLocationCoordinate2D] = []
    @Published var showRoutingError: Bool = false
    private var isRecordingWorkout: Bool = false

    private var allGlobalWaypoints: [MapWaypoint] = []
    private var userClaimedIDs: Set<String> = []
    
    // Designated Injection
    init(
        locationProvider: LocationProviderProtocol,
        dbService: WaypointDatabaseProtocol,
        authSession: AuthSessionProtocol,
        routingProvider: RoutingProviderProtocol
    ) {
        self.locationProvider = locationProvider
        self.dbService = dbService
        self.authSession = authSession
        self.routingProvider = routingProvider
        super.init()

        setupLocationProvider()
        fetchDataStreams()
    }
    
    // SwiftUI
    @MainActor
    override convenience init() {
        self.init(
            locationProvider: CLLocationManager(),
            dbService: FirebaseWaypointDatabase(),
            authSession: FirebaseAuthSession(),
            routingProvider: AppleRoutingProvider()
        )
    }

    private func setupLocationProvider() {
        locationProvider.delegate = self
        locationProvider.desiredAccuracy = kCLLocationAccuracyBest
        locationProvider.requestWhenInUseAuthorization()
        locationProvider.startUpdatingLocation()
    }

    private func fetchDataStreams() {
        dbService.observeGlobalWaypoints { [weak self] waypoints in
            guard let self = self else { return }
            self.allGlobalWaypoints = waypoints
            self.mergeWaypointData()
        }

        if let userId = authSession.currentUserId {
            dbService.observeUserClaimedWaypoints(userId: userId) {
                [weak self] claimedIDs in
                guard let self = self else { return }
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
        self.waypoints = mergedWaypoints
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.userLocation = location

            // Track workout route if active
            if self.isRecordingWorkout {
                self.workoutRoute.append(location.coordinate)
            }

            self.checkWaypointArrival(userLocation: location)
        }
    }
    
    // Workout Control
    
    func startRecordingWorkout() {
        isRecordingWorkout = true
        workoutRoute.removeAll()
    }

    func stopRecordingWorkout() {
        isRecordingWorkout = false
    }
    
    // Waypoint and Tracking
    private func checkWaypointArrival(userLocation: CLLocation) {
        let captureRadiusInMeters: CLLocationDistance = 50.0

        for waypoint in waypoints {
            if waypoint.isClaimed { continue }

            let poiLocation = CLLocation(
                latitude: waypoint.coordinate.latitude,
                longitude: waypoint.coordinate.longitude
            )
            let distance = userLocation.distance(from: poiLocation)

            if distance <= captureRadiusInMeters {
                claimWaypoint(waypoint)
            }
        }
    }

    private func claimWaypoint(_ waypoint: MapWaypoint) {
        guard let userId = authSession.currentUserId else { return }
        if userClaimedIDs.contains(waypoint.id) { return }
        
        userClaimedIDs.insert(waypoint.id)
        mergeWaypointData()
        
        dbService.claimWaypoint(userId: userId, waypointId: waypoint.id, rewardPoints: waypoint.rewardPoints)
    }

    func calculateWalkingRoute(to destination: CLLocationCoordinate2D) {
        guard let userLocation = userLocation else { return }

        self.destinationCoordinate = destination
        self.showRoutingError = false
        self.route = nil
        
        Task {
            do {
                if let newRoute =
                    try await routingProvider.calculateWalkingRoute(
                        from: userLocation.coordinate,
                        to: destination
                    )
                {
                    self.route = newRoute
                } else {
                    self.showRoutingError = true
                    self.clearRoute()
                }
            } catch {
                self.showRoutingError = true
                self.clearRoute()
                print("Failed to get route: \(error.localizedDescription)")
            }
        }
    }

    func clearRoute() {
        self.route = nil
        self.destinationCoordinate = nil
    }
}
