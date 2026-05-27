//
//  LeaderboardRow.swift
//  LarvaDep
//
//  Created by Eko Nur Cahyo S on 27/05/26.
//

import SwiftUI

struct LeaderboardRow: View {
    let rank: Int
    let user: User
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            Text("\(rank)")
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(width: 30)
            
            VStack(alignment: .leading) {
                Text(user.username)
                    .font(.headline)
                    .foregroundColor(isCurrentUser ? .mint : .primary)
                Text(isCurrentUser ? "You" : "Friend")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("\(user.currentStreak)")
                    .font(.headline)
            }
        }
        .padding(.vertical, 4)
    }
}

struct LeaderboardRow_Previews: PreviewProvider {
    static var previews: some View {
        let mockFriend = User(id: "1", username: "Maya Chen", points: 1200, currentStreak: 5, friendList: [], pendingFriendRequests: [], unlockedCustomizations: [])
        let mockSelf = User(id: "USER-123", username: "Dave", points: 800, currentStreak: 3, friendList: [], pendingFriendRequests: [], unlockedCustomizations: [])
        
        Group {
            LeaderboardRow(rank: 1, user: mockFriend, isCurrentUser: false)
                .previewDisplayName("Friend (Light)")
                .preferredColorScheme(.light)
            
            LeaderboardRow(rank: 2, user: mockSelf, isCurrentUser: true)
                .previewDisplayName("Current User (Dark)")
                .preferredColorScheme(.dark)
        }
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
