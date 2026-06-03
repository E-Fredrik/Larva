//
//  FriendRow.swift
//  LarvaDep
//
//  Created by Eko Nur Cahyo S on 27/05/26.
//

import SwiftUI

/// A simple list row displaying a friend's username and current point total.
/// Used in `FriendsView` to render each entry in the accepted friends list.
struct FriendRow: View {
    let user: User
    
    var body: some View {
        HStack {
            Text(user.username)
                .font(.headline)
            Spacer()
            Text("\(user.points) pts")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

