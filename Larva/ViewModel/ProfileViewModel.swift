//
//  ProfileViewModel.swift
//  Larva
//
//  Created by student on 28/05/26.
//

import Foundation
import Combine
import SwiftUI
import FirebaseAuth

class ProfileViewModel: ObservableObject {
    @Published var currentUser: User
    
    @Published var stepsToday: Int = 5230
    @Published var distanceToday: Double = 3.2
    
    var friendCount: Int{
        currentUser.friendList.count
    }
    
    @Published var equippedCustomization: [ShopItem] = [
        ShopItem(id: "theme_midnight", name: "Midnight Mint", description: "Midnight Themed mode map with glowing mint accents", cost: 500, itemType: .mapTheme),
        ShopItem(id: "border_gold", name: "Golden Frame", description: "A Shiny gold border for your leaderboard avatar", cost: 300, itemType: .avatarBorder)
    ]
    init(currentUser: User){
        self.currentUser = currentUser
    }
    
    func logout(){
        do{
            try Auth.auth().signOut()
            print("Successfully logged out \(currentUser.username)")
        } catch{
            print("Error logging out: \(error.localizedDescription)")
        }
    }
}
