//
//  AuthTest.swift
//  LarvaTests
//
//  Created by student on 28/05/26.
//

import Testing
import FirebaseAuth
import FirebaseDatabase
import FirebaseCore
@testable import Larva

@Suite("AuthTest", .serialized)

@MainActor
struct AuthTest {
    
    let testEmail = "testuser_\(UUID().uuidString.prefix(8))@example.com"
    let testPassword = "SuperSecretPassword123!"
    let testUsername = "IntegrationTester"
    
    init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }
    
    @Test("Live System: Sign Up creates a real user in Auth and Realtime Database")
    func testLiveSignUpAndDatabaseCreation() async throws {
        let sut = AuthViewModel()
        
        // Signup User
        await sut.signUp(email: testEmail, password: testPassword, username: testUsername)
        
        // View model state
        #expect(sut.errorMessage.isEmpty, "Expected no errors during live sign up, but got: \(sut.errorMessage)")
        #expect(sut.userSession != nil, "Expected a live FirebaseAuth session to be established")
        #expect(sut.currentUser != nil, "Expected the local User model to be populated")
        #expect(sut.currentUser?.username == testUsername)
        
        // Checks for user after signup
        guard let uid = sut.userSession?.uid else {
            Issue.record("User session UID is missing after sign up")
            return
        }
        
        let dbRef = Database.database().reference()
        let snapshot = try await dbRef.child("users").child(uid).getData()
        
        #expect(snapshot.exists(), "Expected to find a newly created user node in the live Realtime Database")
        
        let dbUsername = snapshot.childSnapshot(forPath: "username").value as? String
        #expect(dbUsername == testUsername, "Expected the database username to match the input")
        
        // Delete user
        try await cleanUpLiveUser(uid: uid)
    }
    
    @Test("Live System: Sign In fetches existing user from Realtime Database")
    func testLiveSignInAndDataFetch() async throws {
        let sut = AuthViewModel()
        
        // Create user from firebase auth
        let authResult = try await Auth.auth().createUser(withEmail: testEmail, password: testPassword)
        let uid = authResult.user.uid
        
        // Inject data
        let dbRef = Database.database().reference()
        try await dbRef.child("users").child(uid).setValue([
            "id": uid,
            "username": "LoginTester",
            "points": 500,
            "currentStreak": 3
        ])
        
        try Auth.auth().signOut()
        
        // Login
        await sut.login(email: testEmail, password: testPassword)
        
        // Check status from firebase
        #expect(sut.errorMessage.isEmpty)
        #expect(sut.userSession?.uid == uid)
        #expect(sut.currentUser != nil)
        #expect(sut.currentUser?.username == "LoginTester")
        #expect(sut.currentUser?.points == 500)
        
        try await cleanUpLiveUser(uid: uid)
    }
    
    @Test("Live System: Sign Out clears local session")
    func testLiveSignOut() async throws {
        let sut = AuthViewModel()
        
        _ = try await Auth.auth().createUser(withEmail: testEmail, password: testPassword)
        await sut.login(email: testEmail, password: testPassword)
        
        guard let uid = sut.userSession?.uid else {
            Issue.record("Failed to establish session for sign out test")
            return
        }
        
        sut.signOut()
        
        #expect(sut.userSession == nil)
        #expect(sut.currentUser == nil)
        #expect(Auth.auth().currentUser == nil, "Expected Firebase Auth global state to be cleared")
        
        try await Auth.auth().signIn(withEmail: testEmail, password: testPassword)
        try await cleanUpLiveUser(uid: uid)
    }
    
    
    // Helper function to delete user just for testing
    private func cleanUpLiveUser(uid: String) async throws {
        let dbRef = Database.database().reference()
        
        try await dbRef.child("users").child(uid).removeValue()
        
        if let currentUser = Auth.auth().currentUser {
            try await currentUser.delete()
        }
    }
}
