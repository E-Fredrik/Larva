import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        userSession = Auth.auth().currentUser
        Task {
            await fetchUserDocument()
        }
    }
    
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = ""
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.userSession = result.user
            await fetchUserDocument()
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func signUp(email: String, password: String, username: String) async {
        isLoading = true
        errorMessage = ""
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.userSession = result.user
            
            let newUser = User(
                id: result.user.uid,
                username: username,
                points: 0,
                currentStreak: 0,
                friendList: [],
                pendingFriendRequests: [],
                unlockedCustomizations: []
            )
            
            try db.collection("users").document(result.user.uid).setData(from: newUser)
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
    
    private func fetchUserDocument() async {
        guard let uid = userSession?.uid else { return }
        do {
            let document = try await db.collection("users").document(uid).getDocument()
            self.currentUser = try document.data(as: User.self)
        } catch {
            print("Error fetching user data: \(error.localizedDescription)")
        }
    }
}
