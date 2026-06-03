//
//  AuthenticatedRootView.swift
//  Larva
//
//  Created by student on 28/05/26.
//

import SwiftUI

/// The root view displayed immediately after a user is authenticated.
///
/// Instantiates all feature ViewModels and injects them as `EnvironmentObject`s
/// so every descendant view can access them without passing them explicitly.
///
/// Layout adapts based on `sizeClass`:
///  - Regular (iPad) → `SidebarNavigationView` with a persistent sidebar.
///  - Compact (iPhone) → `MainTabView` with a bottom tab bar.
///
/// The app's dynamic tint colour from `profileVM.currentAppTint` is applied globally
/// via `.tint()` so all buttons and interactive controls pick it up automatically.
struct AuthenticatedRootView: View {
    /// Used to detect whether the app is running in compact (iPhone) or regular (iPad) mode.
    let sizeClass: UserInterfaceSizeClass?

    /// All ViewModels are owned here as `@StateObject` so their lifetimes are tied to
    /// the authenticated session rather than any individual sub-view.
    @StateObject var friendVM: FriendViewModel
    @StateObject var questVM: QuestViewModel
    @StateObject var shopVM: ShopViewModel
    /// Also injected into the environment, `profileVM` drives theming across all child views.
    @StateObject var profileVM: ProfileViewModel

    /// Initialiser accepts the `User` model returned by `AuthViewModel` so that each
    /// ViewModel can be given the correct user data at construction time.
    init(user: User, sizeClass: UserInterfaceSizeClass?) {
        self.sizeClass = sizeClass
        _friendVM = StateObject(wrappedValue: FriendViewModel(currentUser: user))
        _questVM = StateObject(wrappedValue: QuestViewModel(currentUser: user))
        _shopVM = StateObject(wrappedValue: ShopViewModel())
        _profileVM = StateObject(wrappedValue: ProfileViewModel(currentUser: user))
    }

    var body: some View {
        ZStack {
            // Full-screen app gradient background driven by the equipped theme.
            profileVM.currentAppGradient
                .ignoresSafeArea()
            
            Group {
                // iPad: sidebar navigation for wide-screen layout.
                if sizeClass == .regular {
                    SidebarNavigationView(friendVM: friendVM, questVM: questVM, shopVM: shopVM)
                } else {
                    // iPhone: tab bar navigation for compact layout.
                    MainTabView(friendVM: friendVM, questVM: questVM, shopVM: shopVM)
                }
            }
        }
        .environmentObject(profileVM)
        .tint(profileVM.currentAppTint)
    }
}
