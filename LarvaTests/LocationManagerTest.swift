import CoreLocation
import MapKit
import Testing

@testable import Larva

@Suite("LocationManagerTest")
@MainActor
struct LocationManagerTests {

    @Test("Configures location provider to starts data observation")
    func test_init_configuresServices() async throws {
        let mockLocationProvider = MockLocationProvider()
        let mockDBService = MockWaypointDatabase()
        let mockAuthSession = MockAuthSession(currentUserId: "USER-123")

        let sut = LocationManager(
            locationProvider: mockLocationProvider,
            dbService: mockDBService,
            authSession: mockAuthSession,
            routingProvider: MockRoutingProvider()
        )

        #expect(mockLocationProvider.delegate === sut)
        #expect(mockLocationProvider.didRequestAuthorization)
        #expect(mockLocationProvider.didStartUpdatingLocation)
        #expect(mockDBService.observeGlobalWaypointsCallCount == 1)
        #expect(mockDBService.observeUserClaimedWaypointsCallCount == 1)
        #expect(mockDBService.lastObservedUserId == "USER-123")
    }

    @Test("Merging data correctly updates 'isClaimed' status on waypoints")
    func test_mergeWaypointData_appliesClaimStatus() async throws {
        let mockDBService = MockWaypointDatabase()
        let globalWaypoints = [
            MapWaypoint(
                id: "wp_1",
                name: "Apple",
                coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                rewardPoints: 50
            ),
            MapWaypoint(
                id: "wp_2",
                name: "Campus",
                coordinate: CLLocationCoordinate2D(latitude: 1, longitude: 1),
                rewardPoints: 100
            ),
        ]

        let sut = LocationManager(
            locationProvider: MockLocationProvider(),
            dbService: mockDBService,
            authSession: MockAuthSession(currentUserId: "USER-123"),
            routingProvider: MockRoutingProvider()
        )

        // Simulate Firebase callbacks
        mockDBService.simulateGlobalWaypointsUpdate(globalWaypoints)
        mockDBService.simulateUserClaimsUpdate(["wp_1"])

        #expect(sut.waypoints.count == 2)
        #expect(
            sut.waypoints.first(where: { $0.id == "wp_1" })?.isClaimed == true
        )
        #expect(
            sut.waypoints.first(where: { $0.id == "wp_2" })?.isClaimed == false
        )
    }

    @Test("Location updates publish to userLocation and trigger arrival checks")
    func test_locationUpdate_triggersArrivalCheck() async throws {
        let mockLocationProvider = MockLocationProvider()
        let mockDBService = MockWaypointDatabase()
        let sut = LocationManager(
            locationProvider: mockLocationProvider,
            dbService: mockDBService,
            authSession: MockAuthSession(currentUserId: "USER-123"),
            routingProvider: MockRoutingProvider()
        )

        // Target is at 10, 10
        let targetCoordinate = CLLocationCoordinate2D(
            latitude: 10,
            longitude: 10
        )
        let waypoint = MapWaypoint(
            id: "wp_target",
            name: "Target",
            coordinate: targetCoordinate,
            rewardPoints: 50,
            isClaimed: false
        )
        mockDBService.simulateGlobalWaypointsUpdate([waypoint])

        // Simulate moving directly to the target
        let newLocation = CLLocation(latitude: 10, longitude: 10)
        sut.locationManager(
            CLLocationManager(),
            didUpdateLocations: [newLocation]
        )

        await Task.yield()

        #expect(sut.userLocation?.coordinate.latitude == 10)
        #expect(mockDBService.claimWaypointCallCount == 1)
        #expect(mockDBService.lastClaimedWaypointId == "wp_target")
    }

    @Test("Moving outside the 50m radius and don't trigger a waypoint claim")
    func test_locationUpdate_outsideRadius_doesNotClaim() async throws {
        let mockDBService = MockWaypointDatabase()
        let sut = LocationManager(
            locationProvider: MockLocationProvider(),
            dbService: mockDBService,
            authSession: MockAuthSession(currentUserId: "USER-123"),
            routingProvider: MockRoutingProvider()
        )

        // Target is at 0, 0
        let waypoint = MapWaypoint(
            id: "wp_origin",
            name: "Origin",
            coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            rewardPoints: 50
        )
        mockDBService.simulateGlobalWaypointsUpdate([waypoint])

        // Simulate moving far away
        let farLocation = CLLocation(latitude: 45, longitude: 45)
        sut.locationManager(
            CLLocationManager(),
            didUpdateLocations: [farLocation]
        )
        await Task.yield()

        #expect(mockDBService.claimWaypointCallCount == 0)
    }

    @Test(
        "Routing calculation success updates route and destination properties"
    )
    func test_calculateWalkingRoute_updatesRouteState() async throws {
        let mockRouting = MockRoutingProvider()
        let sut = LocationManager(
            locationProvider: MockLocationProvider(),
            dbService: MockWaypointDatabase(),
            authSession: MockAuthSession(),
            routingProvider: mockRouting
        )

        sut.userLocation = CLLocation(latitude: 0, longitude: 0)
        let destination = CLLocationCoordinate2D(latitude: 1, longitude: 1)

        sut.calculateWalkingRoute(to: destination)
        await Task.yield()

        #expect(mockRouting.calculateCallCount == 1)
        #expect(sut.destinationCoordinate?.latitude == 1)
    }

    @Test("Clear route removes active navigation data")
    func test_clearRoute_resetsData() async throws {
        let sut = LocationManager()
        sut.destinationCoordinate = CLLocationCoordinate2D(
            latitude: 1,
            longitude: 1
        )

        sut.clearRoute()

        #expect(sut.route == nil)
        #expect(sut.destinationCoordinate == nil)
    }
}

final class MockLocationProvider: LocationProviderProtocol {
    weak var delegate: CLLocationManagerDelegate?
    var desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest

    var didRequestAuthorization = false
    var didStartUpdatingLocation = false

    func requestWhenInUseAuthorization() {
        didRequestAuthorization = true
    }

    func startUpdatingLocation() {
        didStartUpdatingLocation = true
    }
}

final class MockWaypointDatabase: WaypointDatabaseProtocol {
    var observeGlobalWaypointsCallCount = 0
    var observeUserClaimedWaypointsCallCount = 0
    var claimWaypointCallCount = 0

    var lastObservedUserId: String?
    var lastClaimedWaypointId: String?

    private var globalCallback: (([MapWaypoint]) -> Void)?
    private var claimsCallback: ((Set<String>) -> Void)?

    func observeGlobalWaypoints(completion: @escaping ([MapWaypoint]) -> Void) {
        observeGlobalWaypointsCallCount += 1
        globalCallback = completion
    }

    func observeUserClaimedWaypoints(
        userId: String,
        completion: @escaping (Set<String>) -> Void
    ) {
        observeUserClaimedWaypointsCallCount += 1
        lastObservedUserId = userId
        claimsCallback = completion
    }

    func claimWaypoint(userId: String, waypointId: String, rewardPoints: Int) {
        claimWaypointCallCount += 1
        lastClaimedWaypointId = waypointId
    }

    // Helpers to inject data
    func simulateGlobalWaypointsUpdate(_ waypoints: [MapWaypoint]) {
        globalCallback?(waypoints)
    }

    func simulateUserClaimsUpdate(_ claims: Set<String>) {
        claimsCallback?(claims)
    }
}

struct MockAuthSession: AuthSessionProtocol {
    var currentUserId: String?
}

final class MockRoutingProvider: RoutingProviderProtocol {
    var calculateCallCount = 0

    func calculateWalkingRoute(
        from source: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D
    ) async throws -> MKRoute? {
        calculateCallCount += 1
        return nil
    }
}
