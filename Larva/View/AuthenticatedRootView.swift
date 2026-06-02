//
//  AuthenticatedRootView.swift
//  Larva
//
//  Created by student on 28/05/26.
//

import SwiftUI

struct AuthenticatedRootView: View {
    let sizeClass: UserInterfaceSizeClass?

    @StateObject var friendVM: FriendViewModel
    @StateObject var questVM: QuestViewModel
    @StateObject var shopVM: ShopViewModel
    @StateObject var profileVM: ProfileViewModel

    init(user: User, sizeClass: UserInterfaceSizeClass?) {
        self.sizeClass = sizeClass
        _friendVM = StateObject(wrappedValue: FriendViewModel(currentUser: user))
        _questVM = StateObject(wrappedValue: QuestViewModel(currentUser: user))
        _shopVM = StateObject(wrappedValue: ShopViewModel())
        _profileVM = StateObject(wrappedValue: ProfileViewModel(currentUser: user))
    }

    var body: some View {
        ZStack {
            profileVM.currentAppGradient
                .ignoresSafeArea()
            
            Group {
                if sizeClass == .regular {
                    SidebarNavigationView(friendVM: friendVM, questVM: questVM, shopVM: shopVM)
                } else {
                    MainTabView(friendVM: friendVM, questVM: questVM, shopVM: shopVM)
                }
            }
        }
        .environmentObject(profileVM)
        .tint(profileVM.currentAppTint)
    }
}
