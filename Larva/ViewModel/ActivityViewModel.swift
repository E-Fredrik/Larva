//
//  ActivityViewModel.swift
//  LarvaLawas
//
//  Created by Eko Nur Cahyo S on 27/05/26.
//

import Foundation
import HealthKit
import Combine

@MainActor
class ActivityViewModel: ObservableObject {
    @Published var currentActivity = ActivityData(steps: 0, caloriesBurned: 0, distanceInMeters: 0, date: Date())
    private var healthStore = HKHealthStore()
    
    // For passive tracking
    func requestAuthorization() {
        // 1. Always check if HealthKit is available on this device first (Crucial for older iPads)
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device.")
            return
        }
        
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        
        healthStore.requestAuthorization(toShare: [], read: [stepType, distanceType, calorieType]) { success, error in
            if success {
                // 2. Push the UI-updating function back to the Main Thread!
                Task { @MainActor in
                    self.fetchTodayData()
                }
            } else if let error = error {
                print("HealthKit Auth Error: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchTodayData() {
        // 3. Implement the query to fetch today's steps
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        // This query sums up all the steps taken since midnight
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            
            guard let result = result, let sum = result.sumQuantity() else {
                print("Failed to fetch steps: \(error?.localizedDescription ?? "No data")")
                return
            }
            
            let steps = Int(sum.doubleValue(for: HKUnit.count()))
            
            // 4. Update your @Published variable on the Main Thread
            DispatchQueue.main.async {
                self.currentActivity.steps = steps
                self.currentActivity.date = now
            }
        }
        
        healthStore.execute(query)
    }
}
