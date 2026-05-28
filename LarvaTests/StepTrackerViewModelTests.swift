//
//  StepTrackerViewModelTests.swift
//  LarvaTests
//
//  Created by Elifele Fredrik on 28/05/26.
//

import FirebaseAuth
import FirebaseDatabase
import Testing

@testable import Larva

@Suite("Step Tracker View Model Tests")
@MainActor
struct StepTrackerViewModelTests {

    let vm: StepTrackerViewModel

    init() {
        vm = StepTrackerViewModel()
    }

    //1. Initial Testing
    @Test("Initial State")
    func initialState() {
        #expect(vm.dailySteps == 0)
        #expect(vm.dailyTarget == 5000)
        #expect(vm.session.isRunning == false)
        #expect(vm.dailyProgress == 0.0)
    }

    //2. Progress Calculation
    @Test("Progress Calculation")
    func dailyProgress() {
        //Inject hardcoded metrics to simulate a workout session, since CMPedometer does not work in unit test/Simulation
        vm.test_setTarget(10000)
        vm.test_injectMetrics(
            passiveSteps: 5000,
            activeSteps: 0,
            distance: 5.0,
            pace: 10.0
        )
        #expect(vm.dailyProgress == 0.5)
    }

    //3. Formatting Distance
    @Test("Formatted Distance outputs correctly based on distance length")
    func formattedDistance() {
        vm.toggleWorkoutSession()

        // Test Under 1km (Should format as meters and round up)
        vm.test_injectMetrics(
            passiveSteps: 0,
            activeSteps: 100,
            distance: 450.5,
            pace: 0
        )
        #expect(vm.formattedDistance == "451 m")

        // Test Over 1km (Should format as kilometers with 2 decimals)
        vm.test_injectMetrics(
            passiveSteps: 0,
            activeSteps: 2000,
            distance: 1540.0,
            pace: 0
        )
        #expect(vm.formattedDistance == "1.54 km")
    }

    //4. Formatting Pace
    @Test("Formatted Pace converts seconds per meter to MM:SS")
    func formattedPace() {
        vm.toggleWorkoutSession()

        // Test zero state
        #expect(vm.formattedPace == "0:00")

        vm.test_injectMetrics(
            passiveSteps: 0,
            activeSteps: 10,
            distance: 10,
            pace: 0.33
        )
        #expect(vm.formattedPace == "5:30")
    }

    //5. Toggle workout session
    @Test("Toggle Workout changes session running state")
    func toggleWorkoutStartsAndStopsCorrectly() {
        #expect(vm.session.isRunning == false)

        vm.toggleWorkoutSession()
        #expect(vm.session.isRunning == true)

        vm.toggleWorkoutSession()
        #expect(vm.session.isRunning == false)
    }

    //6. Step Combination Logic
    @Test("Daily steps should combine passive and active steps correctly")
    func combinedStepTracking() {
        vm.test_injectMetrics(
            passiveSteps: 2000,
            activeSteps: 0,
            distance: 0,
            pace: 0
        )

        vm.toggleWorkoutSession()

        vm.test_injectMetrics(
            passiveSteps: 2000,
            activeSteps: 1500,
            distance: 1000,
            pace: 0.3
        )

        #expect(vm.session.steps == 1500, "Session steps failed.")
        #expect(
            vm.dailySteps == 3500,
            "Daily steps should combine the 2000 passive + 1500 active steps."
        )
    }

    @Test("Fetch Data from Firebase")
    func fetchDataFromFirebase() async throws {
        let testUserId =
            try await FirebaseIntegrationHelper.createAnonymousTestUser()

        //Use defer to cleanup test data from database, this runs before the function ends.
        defer {
            Task {
                await FirebaseIntegrationHelper.cleanupTestData(for: testUserId)
            }
        }
        let dbRef = Database.database().reference()
        try await dbRef.child("users").child(testUserId).child(
            "dailyStepTarget"
        ).setValue(8888)

        await vm.fetchUserDailyTarget()
        #expect(
            vm.dailyTarget == 8888,
            "ViewModel failed to fetch the custom target from Firebase"
        )
    }

    @Test("Upload data to firebase")
    func uploadDataToFirebase() async throws {
        let testUserId =
            try await FirebaseIntegrationHelper.createAnonymousTestUser()
        defer {
            Task {
                await FirebaseIntegrationHelper.cleanupTestData(for: testUserId)
            }
        }
        let dbRef = Database.database().reference()
        let dummyRoute = [RouteCoordinate(lat: -7.2504, lng: 112.7688)]
        vm.attachRouteToSession(dummyRoute)
        try await Task.sleep(nanoseconds: 2_000_000_000) //Sleeps for 2 seconds
        let historySnapshot = try await dbRef.child("users").child(testUserId)
            .child("workoutHistory").getData()

        #expect(
            historySnapshot.exists(),
            "ViewModel failed to upload the workout session to Firebase"
        )

        let historyDict = historySnapshot.value as? [String: Any]
        let firstSession = historyDict?.values.first as? [String: Any]
        let routeArray = firstSession?["route"] as? [[String: Double]]

        #expect(
            routeArray?.first?["lat"] == -7.2504,
            "ViewModel uploaded incorrect GPS coordinates"
        )

    }
}
