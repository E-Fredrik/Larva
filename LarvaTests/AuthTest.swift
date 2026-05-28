//
//  AuthTest.swift
//  LarvaTests
//

import Testing
import Foundation
@testable import Larva

@Suite("AuthViewModel Unit Tests")
@MainActor
struct AuthTest {
    
    @Test("Initialization fetches user data if session already exists")
    func test_init_fetchesUserData() async throws {
        // Fixed: Added friendCode and dailyStepTarget
        let mockUser = User(id: "USER-123", username: "Dave", friendCode: "TEST00", points: 100, currentStreak: 5, dailyStepTarget: 5000, friendList: [], pendingFriendRequests: [], unlockedCustomizations: [], claimedWaypoints: [:])
        
        let authService = MockAuthService(currentUserId: "USER-123")
        let dbService = MockUserDatabase(fetchResult: .success(mockUser))
        
        let sut = AuthViewModel(authService: authService, dbService: dbService)
        await Task.yield()
        
        #expect(sut.currentUserId == "USER-123")
        #expect(sut.currentUser?.username == "Dave")
        #expect(dbService.fetchCallCount == 1)
    }
    
    @Test("Login success updates state and fetches user data")
    func test_login_success() async throws {
        // Fixed: Added friendCode and dailyStepTarget
        let mockUser = User(id: "USER-999", username: "LoginTester", friendCode: "TEST00", points: 0, currentStreak: 0, dailyStepTarget: 5000, friendList: [], pendingFriendRequests: [], unlockedCustomizations: [], claimedWaypoints: [:])
        
        let authService = MockAuthService()
        authService.signInResult = .success("USER-999")
        let dbService = MockUserDatabase(fetchResult: .success(mockUser))
        
        let sut = AuthViewModel(authService: authService, dbService: dbService)
        
        await sut.login(email: "test@test.com", password: "password")
        
        #expect(sut.currentUserId == "USER-999")
        #expect(sut.currentUser?.username == "LoginTester")
        #expect(sut.errorMessage.isEmpty)
        #expect(sut.isLoading == false)
        #expect(authService.signInCallCount == 1)
        #expect(dbService.fetchCallCount == 1)
    }
    
    @Test("Login failure sets error message")
    func test_login_failure() async throws {
        let authService = MockAuthService()
        authService.signInResult = .failure(MockError.networkError)
        let sut = AuthViewModel(authService: authService, dbService: MockUserDatabase())
        
        await sut.login(email: "test@test.com", password: "password")
        
        #expect(sut.currentUserId == nil)
        #expect(sut.currentUser == nil)
        #expect(sut.errorMessage == MockError.networkError.localizedDescription)
    }
    
    @Test("Sign Up success creates session, saves to DB, and updates user state")
    func test_signUp_success() async throws {
        let authService = MockAuthService()
        authService.signUpResult = .success("NEW-USER-ID")
        let dbService = MockUserDatabase()
        
        let sut = AuthViewModel(authService: authService, dbService: dbService)
        
        await sut.signUp(email: "new@test.com", password: "password", username: "Newbie")
        
        #expect(sut.currentUserId == "NEW-USER-ID")
        #expect(sut.currentUser?.username == "Newbie")
        #expect(sut.currentUser?.dailyStepTarget == 5000)
        #expect(sut.currentUser?.friendCode.count == 6) // Verify the generated code is 6 characters
        #expect(authService.signUpCallCount == 1)
        #expect(dbService.saveCallCount == 1)
        #expect(dbService.savedUser?.id == "NEW-USER-ID")
    }
    
    @Test("Sign out clears local session properties")
    func test_signOut_clearsState() async throws {
        let authService = MockAuthService(currentUserId: "USER-123")
        let sut = AuthViewModel(authService: authService, dbService: MockUserDatabase())
        
        // Fixed: Added friendCode and dailyStepTarget
        sut.currentUser = User(id: "USER-123", username: "Dave", friendCode: "TEST00", points: 0, currentStreak: 0, dailyStepTarget: 5000, friendList: [], pendingFriendRequests: [], unlockedCustomizations: [], claimedWaypoints: [:])
        
        sut.signOut()
        
        #expect(sut.currentUserId == nil)
        #expect(sut.currentUser == nil)
        #expect(authService.signOutCallCount == 1)
    }
}

// Mocks and helper functions

enum MockError: Error, LocalizedError {
    case networkError
    var errorDescription: String? { return "Network connection lost." }
}

final class MockAuthService: AuthServiceProviderProtocol {
    var currentUserId: String?
    
    var signInResult: Result<String, Error> = .success("mock-uid")
    var signInCallCount = 0
    
    var signUpResult: Result<String, Error> = .success("mock-uid")
    var signUpCallCount = 0
    
    var signOutCallCount = 0
    
    init(currentUserId: String? = nil) {
        self.currentUserId = currentUserId
    }
    
    func signIn(email: String, password: String) async throws -> String {
        signInCallCount += 1
        return try signInResult.get()
    }
    
    func signUp(email: String, password: String) async throws -> String {
        signUpCallCount += 1
        return try signUpResult.get()
    }
    
    func signOut() throws {
        signOutCallCount += 1
        currentUserId = nil
    }
}

final class MockUserDatabase: UserDatabaseProviderProtocol {
    var fetchResult: Result<User?, Error>
    var fetchCallCount = 0
    
    var saveCallCount = 0
    var savedUser: User?
    
    init(fetchResult: Result<User?, Error> = .success(nil)) {
        self.fetchResult = fetchResult
    }
    
    func fetchUser(uid: String) async throws -> User? {
        fetchCallCount += 1
        return try fetchResult.get()
    }
    
    func saveUser(user: User) async throws {
        saveCallCount += 1
        savedUser = user
    }
}
