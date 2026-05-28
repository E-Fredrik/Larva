//
//  ContentView.swift
//  Larva
//
//  Created by Elifele Fredrik on 24/05/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        Group {
            if authViewModel.userSession != nil {
                TabView {
                    MapHUDView()
                        .tabItem {
                            Label("Map", systemImage: "map.fill")
                        }
                    
                    FriendsView()
                        .tabItem {
                            Label("Social", systemImage: "person.2.fill")
                        }
                }
                .tint(.mint)
            } else {
                LoginView()
            }
        }
        .environmentObject(authViewModel)
    }
}

#Preview {
    ContentView()
}
