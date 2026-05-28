import Combine
import FirebaseAuth
import FirebaseDatabase
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false

    // Realtime Database Reference
    private let dbRef = Database.database().reference()
    private var cancellables = Set<AnyCancellable>()

    init() {
        userSession = Auth.auth().currentUser
        Task {
            await fetchUserData()
        }
    }

    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = ""
        do {
            let result = try await Auth.auth().signIn(
                withEmail: email,
                password: password
            )
            self.userSession = result.user
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
            let result = try await Auth.auth().createUser(
                withEmail: email,
                password: password
            )
            self.userSession = result.user

            let newUser = User(
                id: result.user.uid,
                username: username,
                points: 0,
                currentStreak: 0,
                dailyStepTarget: 5000,
                friendList: [],
                pendingFriendRequests: [],
                unlockedCustomizations: []
            )

            try dbRef.child("users").child(result.user.uid).setValue(
                from: newUser
            )
            self.currentUser = newUser

        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            self.userSession = nil
            self.currentUser = nil
        } catch {
            print("Failed to sign out: \(error.localizedDescription)")
        }
    }

    private func fetchUserData() async {
        guard let uid = userSession?.uid else { return }
        do {

            let snapshot = try await dbRef.child("users").child(uid).getData()

            if snapshot.exists() {

                self.currentUser = try snapshot.data(as: User.self)
            }
        } catch {
            print("Error fetching user data: \(error.localizedDescription)")
        }
    }
}
