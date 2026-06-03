//
//  AuthViewModel.swift
//  LarvaLawas
//

import Combine
import FirebaseAuth
import FirebaseDatabase
import SwiftUI

// MARK: - Dependency Protocols

/// Abstracts Firebase Authentication so `AuthViewModel` can be tested
/// with a mock that doesn't hit the network.
protocol AuthServiceProviderProtocol {
    /// Returns the UID of the currently signed-in user, or `nil` if no session exists.
    var currentUserId: String? { get }
    func signIn(email: String, password: String) async throws -> String
    func signUp(email: String, password: String) async throws -> String
    func signOut() throws
}

/// Abstracts Realtime Database read/write so `AuthViewModel` can be tested
/// without a live database connection.
protocol UserDatabaseProviderProtocol {
    func fetchUser(uid: String) async throws -> User?
    func saveUser(user: User) async throws
}

// MARK: - Production Implementations

/// Wraps the Firebase Auth SDK so it conforms to `AuthServiceProviderProtocol`.
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

/// Wraps Firebase Realtime Database reads and writes for the `users` node.
struct FirebaseUserDatabaseProvider: UserDatabaseProviderProtocol {
    private let dbRef = Database.database().reference()

    /// Fetches the user record at `users/<uid>`. Returns `nil` if the node doesn't exist.
    func fetchUser(uid: String) async throws -> User? {
        let snapshot = try await dbRef.child("users").child(uid).getData()
        if snapshot.exists() {
            return try snapshot.data(as: User.self)
        }
        return nil
    }

    /// Persists the full `User` struct to `users/<user.id>`, overwriting any existing data.
    func saveUser(user: User) async throws {
        try dbRef.child("users").child(user.id).setValue(from: user)
    }
}

// MARK: - ViewModel

/// Manages the full authentication lifecycle: sign-in, sign-up, sign-out, and
/// loading the user's profile from Firebase after the session is established.
///
/// Runs on `@MainActor` so that all `@Published` property updates happen on the
/// main thread without explicit `DispatchQueue.main.async` calls.
@MainActor
class AuthViewModel: ObservableObject {

    /// Firebase UID of the signed-in user. `nil` when unauthenticated.
    @Published var currentUserId: String?
    /// Full profile loaded from Realtime Database. May be `nil` briefly after
    /// sign-in while the fetch is in-flight.
    @Published var currentUser: User?
    /// Human-readable error text displayed below the login/sign-up form.
    @Published var errorMessage: String = ""
    /// `true` while an async auth operation (sign-in / sign-up) is running.
    @Published var isLoading: Bool = false

    private let authService: AuthServiceProviderProtocol
    private let dbService: UserDatabaseProviderProtocol

    /// Dependency-injected initialiser for testing – pass mock implementations
    /// of `AuthServiceProviderProtocol` and `UserDatabaseProviderProtocol` to
    /// avoid hitting Firebase during unit tests.
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

    /// Default convenience initialiser used by SwiftUI – wires up the real Firebase
    /// auth and database providers automatically.
    @MainActor
    convenience init() {
        self.init(
            authService: FirebaseAuthProvider(),
            dbService: FirebaseUserDatabaseProvider()
        )
    }

    /// Signs the user in with email and password.
    /// On success, fetches the user's profile from Firebase.
    /// On failure, stores the error message for display in `LoginView`.
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

    /// Creates a new Firebase Auth account, generates a unique friend code,
    /// builds the initial `User` record, and saves it to the database.
    func signUp(email: String, password: String, username: String) async {
        isLoading = true
        errorMessage = ""
        do {
            let uid = try await authService.signUp(
                email: email,
                password: password
            )
            self.currentUserId = uid

            // Generate a random 6-character alphanumeric friend code
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

    /// Signs the user out from Firebase Auth and clears the local session state.
    func signOut() {
        do {
            try authService.signOut()
            self.currentUserId = nil
            self.currentUser = nil
        } catch {
            print("Failed to sign out: \(error.localizedDescription)")
        }
    }

    /// Fetches the `User` document for the currently authenticated UID.
    /// Called automatically after sign-in and on init if a session already exists.
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
