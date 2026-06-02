//
//  CustomAvatarView.swift
//  Larva
//
//  Created by Elifele Fredrik on 02/06/26.
//

import SwiftUI

struct CustomAvatarView: View {
    let user: User
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
