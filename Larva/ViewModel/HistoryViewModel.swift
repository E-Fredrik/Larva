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

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var pastWorkouts: [WorkoutData] = []
    @Published var isLoading: Bool = false

    private let dbRef = Database.database().reference()
    private var isListening = false

    private func safeDecodeWorkout(from dict: [String: Any]) -> WorkoutData? {
        var safeDict = dict

        if safeDict["route"] == nil {
            safeDict["route"] = [Any]()
        }

        guard
            let jsonData = try? JSONSerialization.data(
                withJSONObject: safeDict
            ),
            let workout = try? JSONDecoder().decode(
                WorkoutData.self,
                from: jsonData
            )
        else {
            return nil
        }
        return workout
    }

    func startListeningForHistory(userId: String) {
        guard !isListening else { return }
        isListening = true
        self.isLoading = true

        dbRef.child("users").child(userId).child("workoutHistory").observe(
            .value
        ) { [weak self] snapshot in
            guard let self = self else { return }
            self.isLoading = false

            guard snapshot.exists(), let dict = snapshot.value as? [String: Any]
            else {
                self.pastWorkouts = []
                return
            }

            var fetchedWorkouts: [WorkoutData] = []
            
            for (_, value) in dict {
                if let workoutDict = value as? [String: Any],
                    let workout = self.safeDecodeWorkout(from: workoutDict)
                {

                    if workout.steps > 0 || workout.distanceInMeters > 0 {
                        fetchedWorkouts.append(workout)
                    }
                }
            }

            self.pastWorkouts = fetchedWorkouts.sorted {
                $0.startDate > $1.startDate
            }
        }
    }
}
