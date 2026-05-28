//
//  WatchConnectivityManager.swift
//  Larva
//
//  Created by Elifele Fredrik on 28/05/26.
//

import Combine
import Foundation
import WatchConnectivity

class WatchConnectivityManager: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = WatchConnectivityManager()

    @Published var completedWatchWorkout: WorkoutData?
    
    @Published var remoteWorkoutState: Bool? = nil

    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    // Sends live state to the phone
    func sendWorkoutState(isRunning: Bool) {
        guard WCSession.isSupported() else { return }
        let payload = ["workoutState": isRunning]
        if WCSession.default.isReachable {
            print("Iphone is reachable")
            WCSession.default.sendMessage(
                payload,
                replyHandler: nil,
                errorHandler: { error in
                    print("Failed to send workout state: \(error)")
                    try? WCSession.default.updateApplicationContext(payload)
                }
            )
        } else {
            //Queues the state to be sent when the phone becomes reachable
            print("Iphone is not reachable, updating application context")
            try? WCSession.default.updateApplicationContext(payload)
        }
    }

    func sendWorkoutToPhone(_ workout: WorkoutData) {
        guard WCSession.isSupported() else { return }
        do {
            let data = try JSONEncoder().encode(workout)
            WCSession.default.transferUserInfo(["workoutPayload": data])
            print("Sent workout data to phone: \(workout)")
        } catch {
            print("Failed to encode workout data: \(error)")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleStateMessage(message)
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        handleStateMessage(applicationContext)
    }
    
    private func handleStateMessage(_ payload: [String: Any]) {
        if let workoutState = payload["workoutState"] as? Bool {
            DispatchQueue.main.async {
                self.remoteWorkoutState = workoutState
            }
        }
    }

    func session(
        _ session: WCSession,
        didReceiveUserInfo userInfo: [String: Any] = [:]
    ) {
        if let data = userInfo["workoutPayload"] as? Data {
            do {
                let workout = try JSONDecoder().decode(
                    WorkoutData.self,
                    from: data
                )
                DispatchQueue.main.async {
                    self.completedWatchWorkout = workout
                    print("Received workout data from watch: \(workout)")
                }
            } catch {
                print("Failed to decode workout data: \(error)")
            }
        }
    }
    
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    #endif
    
}
