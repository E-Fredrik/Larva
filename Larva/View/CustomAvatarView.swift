//
//  CustomAvatarView.swift
//  Larva
//
//  Created by Elifele Fredrik on 02/06/26.
//

import SwiftUI

/// A circular avatar that shows the first letter of the user's username.
///
/// If the user has an `avatarBorder` item equipped, `ProfileViewModel.getBorderColor(for:)`
/// returns a `Color` which is drawn as a ring around the circle.
/// Used wherever a user avatar is needed (profile, leaderboard, friend detail).
struct CustomAvatarView: View {
    let user: User
    /// Controls the diameter of the avatar circle. Defaults to 80 pt.
    var size: CGFloat = 80
    
    @EnvironmentObject var profileVM: ProfileViewModel
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.primary.opacity(0.1))
            
            Text(String(user.username.prefix(1)).uppercased())
                .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            if let borderColor = profileVM.getBorderColor(for: user) {
                Circle()
                    .stroke(borderColor, lineWidth: size * 0.06)
            }
        }
        .frame(width: size, height: size)
    }
}
