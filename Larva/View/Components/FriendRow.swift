//
//  FriendRow.swift
//  LarvaDep
//
//  Created by Eko Nur Cahyo S on 27/05/26.
//

import SwiftUI

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

