//
//  AuthViewModel.swift
//  LarvaLawas
//

import Combine
import FirebaseAuth
import FirebaseDatabase
import SwiftUI

// Dependency Protocols

protocol AuthServiceProviderProtocol {
    var currentUserId: String? { get }
    func signIn(email: String, password: String) async throws -> String
    func signUp(email: String, password: String) async throws -> String
    func signOut() throws
}

protocol UserDatabaseProviderProtocol {
    func fetchUser(uid: String) async throws -> User?
    func saveUser(user: User) async throws
}

// Production Implementations
struct FirebaseAuthProvider: AuthServiceProviderProtocol {
    var currentUserId: String? { Auth.auth().currentUser?.uid }

    func signIn(email: String, password: String) async throws -> String {
        let result = try await Auth.auth().signIn(
            withEmail: email,
            password: password
        )
        return result.user.uid
    }

    func signUp(email: String, password: String) async throws -> String {
        let result = try await Auth.auth().createUser(
            withEmail: email,
            password: password
        )
        return result.user.uid
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }
}

struct FirebaseUserDatabaseProvider: UserDatabaseProviderProtocol {
    private let dbRef = Database.database().reference()

    func fetchUser(uid: String) async throws -> User? {
        let snapshot = try await dbRef.child("users").child(uid).getData()
        if snapshot.exists() {
            return try snapshot.data(as: User.self)
        }
        return nil
    }

    func saveUser(user: User) async throws {
        try dbRef.child("users").child(user.id).setValue(from: user)
    }
}

// ViewModels
@MainActor
class AuthViewModel: ObservableObject {

    @Published var currentUserId: String?
    @Published var currentUser: User?
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false

    private let authService: AuthServiceProviderProtocol
    private let dbService: UserDatabaseProviderProtocol

    // Initializer for Testings
    init(
        authService: AuthServiceProviderProtocol,
        dbService: UserDatabaseProviderProtocol
    ) {
        self.authService = authService
        self.dbService = dbService
        self.currentUserId = authService.currentUserId

        Task {
            await fetchUserData()
        }
    }

    // Initializer for SwiftUi
    @MainActor
    convenience init() {
        self.init(
            authService: FirebaseAuthProvider(),
            dbService: FirebaseUserDatabaseProvider()
        )
    }

    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = ""
        do {
            let uid = try await authService.signIn(
                email: email,
                password: password
            )
            self.currentUserId = uid
            await fetchUserData()
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signUp(email: String, password: String, username: String) async {
        isLoading = true
        errorMessage = ""
        do {
            let uid = try await authService.signUp(
                email: email,
                password: password
            )
            self.currentUserId = uid

            let generatedCode = String(
                (0..<6).map { _ in
                    "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement()!
                }
            )

            let newUser = User(
                id: uid,
                username: username,
                friendCode: generatedCode,
                points: 0,
                currentStreak: 0,
                dailyStepTarget: 5000,
                friendList: [],
                pendingFriendRequests: [],
                unlockedCustomizations: [],
                claimedWaypoints: [:]
            )

            try await dbService.saveUser(user: newUser)
            self.currentUser = newUser

        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signOut() {
        do {
            try authService.signOut()
            self.currentUserId = nil
            self.currentUser = nil
        } catch {
            print("Failed to sign out: \(error.localizedDescription)")
        }
    }

    private func fetchUserData() async {
        guard let uid = currentUserId else { return }
        do {
            if let user = try await dbService.fetchUser(uid: uid) {
                self.currentUser = user
            }
        } catch {
            print("Error fetching user data: \(error.localizedDescription)")
        }
    }
}
