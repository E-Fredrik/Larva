//
//  StepTrackerViewModelTests.swift
//  LarvaTests
//
//  Created by Elifele Fredrik on 28/05/26.
//

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

        vm.test_injectMetrics(passiveSteps: 0, activeSteps: 10, distance: 10, pace: 0.33)
        #expect(vm.formattedPace == "5:30")
    }
}
