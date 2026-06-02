//
//  CustomAvatarView.swift
//  Larva
//
//  Created by Elifele Fredrik on 02/06/26.
//

import SwiftUI

struct CustomAvatarView: View {
    @EnvironmentObject var profileVM: ProfileViewModel
    var username: String
    var size: CGFloat = 80
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.3))
            
            Text(String(username.prefix(1)).uppercased())
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundColor(.primary)
            
            if let borderItem = profileVM.equippedItems[ShopItem.ItemType.avatarBorder.rawValue] {
                Image(borderItem.id)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 1.15, height: size * 1.15)
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    CustomAvatarView(username: "Larva")
        .environmentObject(ProfileViewModel(currentUser:
            User(
            id: "USER-123",
            username: "Maya Chen",
            friendCode: "MCH123",
            points: 2500,
            currentStreak: 89,
            dailyStepTarget: 10000,
            friendList: ["user2", "user3"],
            pendingFriendRequests: [],
            unlockedCustomizations: ["ITEM-001", "ITEM-002"],
            claimedWaypoints: [:]
        )))
}
