//
//  AuthenticatedRootView.swift
//  Larva
//
//  Created by student on 28/05/26.
//

import SwiftUI

struct AuthenticatedRootView: View {
    let sizeClass: UserInterfaceSizeClass?
    
    // ViewModels initialized with the REAL Firebase user
    @StateObject var friendVM: FriendViewModel
    @StateObject var questVM: QuestViewModel
    @StateObject var shopVM: ShopViewModel
    
    init(user: User, sizeClass: UserInterfaceSizeClass?) {
        self.sizeClass = sizeClass
        
        // Dynamically inject the fetched Firebase user into the StateObjects
        _friendVM = StateObject(wrappedValue: FriendViewModel(currentUser: user))
        _questVM = StateObject(wrappedValue: QuestViewModel(currentUser: user))
        _shopVM = StateObject(wrappedValue: ShopViewModel(currentUser: user))
    }
    
    var body: some View {
        Group {
            // 4. Preserve your iPad vs iPhone responsive routing
            if sizeClass == .regular {
                SidebarNavigationView(friendVM: friendVM, questVM: questVM, shopVM: shopVM)
            } else {
                MainTabView(friendVM: friendVM, questVM: questVM, shopVM: shopVM)
            }
        }
        .tint(.mint)
    }
}
