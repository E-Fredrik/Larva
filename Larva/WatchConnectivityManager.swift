//
//  WatchConnectivityManager.swift
//  Larva
//
//  Created by Elifele Fredrik on 28/05/26.
//

import Combine
import Foundation
import WatchConnectivity

/// Singleton that manages two-way communication between the iOS app and the Apple Watch
/// companion app using `WatchConnectivity`.
///
/// Two types of data are exchanged:
///  1. **Workout state** (`workoutState: Bool`): Sent via real-time messages when the watch
///     is reachable, or via `applicationContext` when it isn't. This allows either device
///     to start/stop a workout and have the other reflect the change immediately.
///
///  2. **Completed workout** (`workoutPayload: Data`): Sent via `transferUserInfo` (guaranteed
///     delivery) when the Watch ends a session, so the iPhone can save the route to Firebase.
class WatchConnectivityManager: NSObject, WCSessionDelegate, ObservableObject {
    /// Shared singleton – created once in `LarvaApp.onAppear` to activate the session early.
    static let shared = WatchConnectivityManager()

    /// Set when the Watch sends a completed `WorkoutData` payload to the iPhone.
    /// Observed by `StepTrackerViewModel` to save the route to Firebase.
    @Published var completedWatchWorkout: WorkoutData?
    
    /// The latest workout-running state received from the remote device.
    /// `true` = workout started remotely, `false` = workout stopped remotely, `nil` = no message yet.
    @Published var remoteWorkoutState: Bool? = nil

    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    /// Sends the current workout running state to the paired device.
    /// Prefers real-time `sendMessage` when the counterpart is reachable;
    /// falls back to `updateApplicationContext` (queued delivery) when it isn't.
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

    /// Encodes `workout` as JSON and sends it to the iPhone via `transferUserInfo`,
    /// which guarantees delivery even if the phone is not currently reachable.
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
    
    /// Called when a real-time message arrives (watch is reachable and awake).
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleStateMessage(message)
    }
    
    /// Called when an `applicationContext` update arrives (counterpart was unreachable at send time).
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        handleStateMessage(applicationContext)
    }
    
    /// Extracts the `workoutState` bool from a received message payload and publishes it
    /// on the main thread so SwiftUI subscribers update without a manual `DispatchQueue` call.
    private func handleStateMessage(_ payload: [String: Any]) {
        if let workoutState = payload["workoutState"] as? Bool {
            DispatchQueue.main.async {
                self.remoteWorkoutState = workoutState
            }
        }
    }

    /// Called when the iPhone receives a `transferUserInfo` delivery containing a
    /// serialised `WorkoutData` blob. Decodes and publishes it on the main thread.
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
    
    /// Required `WCSessionDelegate` method. Called when session activation completes.
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}
    
    #if os(iOS)
    /// iOS-only: called when the session transitions to inactive state (e.g. watch switched).
    func sessionDidBecomeInactive(_ session: WCSession) {}
    /// iOS-only: called when the session fully deactivates. Re-activates to handle watch pairing changes.
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    #endif
    
}
