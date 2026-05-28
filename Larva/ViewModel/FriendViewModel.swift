//
//  FriendViewModel.swift
//  Larva
//
//  Created by student on 28/05/26.
//

import Combine
import FirebaseDatabase
import Foundation

@MainActor
class FriendViewModel: ObservableObject {
    @Published var currentUser: User
    @Published var friends: [User] = []
    @Published var pendingRequests: [User] = []

    private let dbRef = Database.database().reference()

    // Derived property that automatically sorts friends by their current streak
    var leaderboard: [User] {
        var allUsers = friends
        allUsers.append(currentUser)  // Include the user in their own leaderboard
        return allUsers.sorted { $0.currentStreak > $1.currentStreak }
    }

    init(currentUser: User) {
        self.currentUser = currentUser
        Task {
            await fetchFriendsData()
        }
    }

    func sendFriendRequest(to code: String) {
        guard code != currentUser.friendCode else { return }

        Task {
            do {
                let query = dbRef.child("users").queryOrdered(
                    byChild: "friendCode"
                ).queryEqual(toValue: code)
                let snapshot = try await query.getData()

                guard snapshot.exists(),
                    let children = snapshot.children.allObjects
                        as? [DataSnapshot],
                    let firstChild = children.first,
                    var targetUser = try? firstChild.data(as: User.self)
                else {
                    print("User with Friend Code \(code) not found.")
                    return
                }

                // Avoid duplicate requests
                if !targetUser.pendingFriendRequests.contains(currentUser.id)
                    && !targetUser.friendList.contains(currentUser.id)
                {
                    targetUser.pendingFriendRequests.append(currentUser.id)

                    // Save it back to the target user's actual UID folder
                    try dbRef.child("users").child(targetUser.id).setValue(
                        from: targetUser
                    )
                    print("Friend request sent to \(targetUser.username)!")
                }
            } catch {
                print("Error sending request: \(error.localizedDescription)")
            }
        }
    }

    func acceptRequest(from user: User) {
        //Update Current User
        if !currentUser.friendList.contains(user.id) {
            currentUser.friendList.append(user.id)
            friends.append(user)
        }
        currentUser.pendingFriendRequests.removeAll { $0 == user.id }
        pendingRequests.removeAll { $0.id == user.id }

        Task {
            do {
                try dbRef.child("users").child(currentUser.id).setValue(
                    from: currentUser
                )

                //Update the other user's friend list
                var acceptedUser = user
                if !acceptedUser.friendList.contains(currentUser.id) {
                    acceptedUser.friendList.append(currentUser.id)
                    try dbRef.child("users").child(acceptedUser.id).setValue(
                        from: acceptedUser
                    )
                }
                print("Accepted friend request from \(user.username)!")
            } catch {
                print("Error accepting request: \(error.localizedDescription)")
            }
        }
    }

    func declineRequest(from user: User) {
        currentUser.pendingFriendRequests.removeAll { $0 == user.id }
        pendingRequests.removeAll { $0.id == user.id }

        Task {
            do {
                try dbRef.child("users").child(currentUser.id).setValue(
                    from: currentUser
                )
            } catch {
                print("Error declining request: \(error.localizedDescription)")
            }
        }
    }

    private func fetchFriendsData() async {
        do {
            //Fetch established friends
            var fetchedFriends: [User] = []
            for friendID in currentUser.friendList {
                let snapshot = try await dbRef.child("users").child(friendID)
                    .getData()
                if let friend = try? snapshot.data(as: User.self) {
                    fetchedFriends.append(friend)
                }
            }
            self.friends = fetchedFriends

            //Fetch pending requests
            var fetchedRequests: [User] = []
            for requestID in currentUser.pendingFriendRequests {
                let snapshot = try await dbRef.child("users").child(requestID)
                    .getData()
                if let requestUser = try? snapshot.data(as: User.self) {
                    fetchedRequests.append(requestUser)
                }
            }
            self.pendingRequests = fetchedRequests

        } catch {
            print("Error fetching friends data: \(error.localizedDescription)")
        }
    }
}
