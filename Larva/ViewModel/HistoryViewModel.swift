//
//  WorkoutSessionInfo.swift
//  Larva
//
//  Created by Elifele Fredrik on 06/06/26.
//

import Combine
import FirebaseAuth
import FirebaseDatabase
import Foundation

struct WorkoutSessionInfo: Identifiable {
    let id: String
    let data: WorkoutData
}

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var pastWorkouts: [WorkoutSessionInfo] = []
    @Published var isLoading: Bool = false
    
    private let dbRef = Database.database().reference()
    
    func fetchWorkoutHistory(userId: String) async {
        self.isLoading = true
        defer { self.isLoading = false }
        
        do {
            let snapshot = try await dbRef.child("users").child(userId).child("workoutHistory").getData()
            guard snapshot.exists(), let dict = snapshot.value as? [String: Any] else { return }
            
            var fetchedWorkouts: [WorkoutSessionInfo] = []
            let decoder = JSONDecoder()
            
            for (key, value) in dict {
                if let workoutDict = value as? [String: Any],
                   let jsonData = try? JSONSerialization.data(withJSONObject: workoutDict),
                   let workout = try? decoder.decode(WorkoutData.self, from: jsonData) {
                    fetchedWorkouts.append(WorkoutSessionInfo(id: key, data: workout))
                }
            }
            
            // Sort by newest workout first
            self.pastWorkouts = fetchedWorkouts.sorted { $0.data.startDate > $1.data.startDate }
        } catch {
            print("Failed to fetch workout history: \(error.localizedDescription)")
        }
    }
}
