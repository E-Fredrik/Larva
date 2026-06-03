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

// MARK: - Dependency Protocols

/// Abstracts `CLLocationManager` so `LocationManager` can be tested
/// without a real device or simulator GPS session.
protocol LocationProviderProtocol: AnyObject {
    var delegate: CLLocationManagerDelegate? { get set }
    var desiredAccuracy: CLLocationAccuracy { get set }
    func requestWhenInUseAuthorization()
    func startUpdatingLocation()
}

/// Conformance extension that makes the real `CLLocationManager` satisfy `LocationProviderProtocol`.
extension CLLocationManager: LocationProviderProtocol {}

/// Abstracts Firebase Realtime Database operations for waypoints,
/// enabling unit-testable waypoint logic without network calls.
protocol WaypointDatabaseProtocol {
    /// Starts a persistent observer that delivers all global waypoints whenever the
    /// `waypoints` Firebase node changes.
    func observeGlobalWaypoints(completion: @escaping ([MapWaypoint]) -> Void)
    /// Observes which waypoints the given user has already claimed.
    func observeUserClaimedWaypoints(
        userId: String,
        completion: @escaping (Set<String>) -> Void
    )
    /// Marks a waypoint as claimed for the user and atomically increments their point balance.
    func claimWaypoint(userId: String, waypointId: String, rewardPoints: Int)
}

/// Provides the UID of the currently authenticated Firebase user.
protocol AuthSessionProtocol {
    var currentUserId: String? { get }
}

/// Abstracts MapKit route calculation so routing can be tested without network requests.
protocol RoutingProviderProtocol {
    func calculateWalkingRoute(
        from source: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D
    ) async throws -> MKRoute?
}

// MARK: - Production Implementations

/// Wraps `Firebase.Auth` to provide the current user's UID without exposing the full Auth SDK.
struct FirebaseAuthSession: AuthSessionProtocol {
    var currentUserId: String? { Auth.auth().currentUser?.uid }
}

/// Reads and writes waypoint data to/from the Firebase Realtime Database.
struct FirebaseWaypointDatabase: WaypointDatabaseProtocol {
    private let dbRef = Database.database(url: "https://larvva-d2753-default-rtdb.asia-southeast1.firebasedatabase.app").reference()

    /// Attaches a persistent `.value` listener to the `waypoints` node and calls `completion`
    /// with a decoded array of `MapWaypoint` objects every time the data changes.
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

    /// Attaches a persistent `.value` listener to `users/<userId>/claimedWaypoints`
    /// and returns a `Set` of waypoint IDs where the value is `true`.
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

    /// Writes `waypointId: true` to the user's `claimedWaypoints` node, and uses a
    /// Firebase transaction to safely increment `points` by `rewardPoints` even under
    /// concurrent updates from multiple devices.
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

/// Uses MapKit Directions to calculate a walking-mode route between two coordinates.
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

// MARK: - ViewModel

/// Manages the user's real-time location, map waypoints, and workout route recording.
///
/// Responsibilities:
///  - Receives GPS updates from `CLLocationManager` and publishes `userLocation`.
///  - Observes the global waypoints list and the user's claimed set from Firebase,
///    merging them into a single `waypoints` array for the map.
///  - Detects when the user walks within 50 m of an unclaimed waypoint and auto-claims it.
///  - Records GPS coordinates into `workoutRoute` during an active workout session.
///  - Calculates walking routes to tapped destinations via MapKit Directions.
@MainActor
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    // Injected Dependencies
    private var locationProvider: LocationProviderProtocol
    private var dbService: WaypointDatabaseProtocol
    private var authSession: AuthSessionProtocol
    private var routingProvider: RoutingProviderProtocol

    /// The most recent GPS fix received from `CLLocationManager`.
    @Published var userLocation: CLLocation?
    /// The current walking route to display as a blue polyline on the map.
    @Published var route: MKRoute?
    /// The coordinate the user tapped/selected as their navigation destination.
    @Published var destinationCoordinate: CLLocationCoordinate2D?
    /// Merged list of all global waypoints with their claimed status for the current user.
    @Published var waypoints: [MapWaypoint] = []

    // Workout Tracking Properties
    /// Ordered GPS coordinates recorded since the last `startRecordingWorkout()` call.
    /// Drawn as an orange polyline on the map while a workout is active.
    @Published var workoutRoute: [CLLocationCoordinate2D] = []
    /// Set to `true` and shown to the user when MapKit cannot find a walking route.
    @Published var showRoutingError: Bool = false
    /// Internal flag toggled by `startRecordingWorkout` / `stopRecordingWorkout`.
    private var isRecordingWorkout: Bool = false

    /// All waypoints fetched from the global Firebase `waypoints` node (before merging claimed state).
    private var allGlobalWaypoints: [MapWaypoint] = []
    /// Set of waypoint IDs the current user has already claimed, synced from Firebase.
    private var userClaimedIDs: Set<String> = []
    
    /// Full dependency-injection initialiser used in tests.
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
    
    /// Convenience initialiser for SwiftUI – wires up all real production services.
    @MainActor
    override convenience init() {
        self.init(
            locationProvider: CLLocationManager(),
            dbService: FirebaseWaypointDatabase(),
            authSession: FirebaseAuthSession(),
            routingProvider: AppleRoutingProvider()
        )
    }

    /// Configures the location provider with best accuracy and requests when-in-use
    /// authorization before starting continuous updates.
    private func setupLocationProvider() {
        locationProvider.delegate = self
        locationProvider.desiredAccuracy = kCLLocationAccuracyBest
        locationProvider.requestWhenInUseAuthorization()
        locationProvider.startUpdatingLocation()
    }

    /// Kicks off Firebase observers for both the global waypoints list and the
    /// user's personal claimed-waypoints list. Each update triggers a merge.
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

    /// Combines the raw global waypoints with the user's claimed IDs so that
    /// `waypoints` always reflects the current claimed state without a refetch.
    private func mergeWaypointData() {
        var mergedWaypoints = allGlobalWaypoints
        for i in 0..<mergedWaypoints.count {
            if userClaimedIDs.contains(mergedWaypoints[i].id) {
                mergedWaypoints[i].isClaimed = true
            }
        }
        self.waypoints = mergedWaypoints
    }

    /// `CLLocationManagerDelegate` callback. Runs `nonisolated` to avoid blocking
    /// the main thread on every GPS ping, then dispatches UI updates onto `@MainActor`.
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
    
    // MARK: - Workout Control
    
    /// Starts recording GPS coordinates into `workoutRoute` and resets any previous route.
    /// Called by `MapHUDView` when the user begins a workout session.
    func startRecordingWorkout() {
        isRecordingWorkout = true
        workoutRoute.removeAll()
    }

    /// Stops recording GPS coordinates. The route is finalised and can be retrieved
    /// from `workoutRoute` for attaching to the `WorkoutData` session.
    func stopRecordingWorkout() {
        isRecordingWorkout = false
    }
    
    // MARK: - Waypoint Proximity Detection

    /// Checks every unclaimed waypoint to see if the user has walked within the
    /// 50 m capture radius. Triggers `claimWaypoint(_:)` for any matches.
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

    /// Optimistically marks the waypoint as claimed in the local array (so the UI
    /// updates immediately) and then persists the claim to Firebase.
    private func claimWaypoint(_ waypoint: MapWaypoint) {
        guard let userId = authSession.currentUserId else { return }
        if userClaimedIDs.contains(waypoint.id) { return }
        
        userClaimedIDs.insert(waypoint.id)
        mergeWaypointData()
        
        dbService.claimWaypoint(userId: userId, waypointId: waypoint.id, rewardPoints: waypoint.rewardPoints)
    }

    /// Requests a walking-mode MapKit route from the user's current location to `destination`.
    /// Clears any existing route while the request is in-flight and sets `showRoutingError`
    /// if no route can be found.
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

    /// Clears the currently displayed route and destination marker from the map.
    func clearRoute() {
        self.route = nil
        self.destinationCoordinate = nil
    }
}
