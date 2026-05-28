//
//  FirebaseIntegrationHelper.swift
//  Larva
//
//  Created by Elifele Fredrik on 28/05/26.
//


import Foundation
import FirebaseAuth
import FirebaseDatabase

struct FirebaseIntegrationHelper {
    static func createAnonymousTestUser() async throws -> String {
        let authResult = try await Auth.auth().signInAnonymously()
        return authResult.user.uid
    }
    
    static func cleanupTestData(for userId: String) async {
        let dbRef = Database.database().reference()
        
        do {
            try await dbRef.child("users").child(userId).removeValue()
            try await Auth.auth().currentUser?.delete()
            
            print("Cleanup Successful: Removed test data for user \(userId)")
        } catch {
            print("Cleanup Failed: \(error.localizedDescription)")
        }
    }
}
