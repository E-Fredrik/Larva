//
//  ShopView.swift
//  Larva
//
//  Created by student on 28/05/26.
//

import SwiftUI

struct ShopView: View {
    @ObservedObject var viewModel: ShopViewModel
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                ZStack {
                    VStack(spacing: 0) {
                        // Current Balance Header
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Your Balance")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                HStack(spacing: 6) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                    Text("\(viewModel.currentUser.points)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                }
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(16)
                        .padding(.horizontal)
                        .padding(.top, 16)
                        
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(viewModel.storeItems) { item in
                                    ShopItemCard(
                                        item: item,
                                        isOwned: viewModel.owns(item: item),
                                        canAfford: viewModel.currentUser.points >= item.cost
                                    ) {
                                        withAnimation {
                                            viewModel.purchase(item: item)
                                        }
                                    }
                                }
                            }
                            .padding()
                            
                            Spacer().frame(height: 100)
                        }
                    }
                    
                    VStack {
                        Spacer()
                        Text("Spend points earned from walking and completing quests to unlock app customizations.")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.thinMaterial)
                            .cornerRadius(16)
                            .padding(.horizontal)
                            .padding(.bottom, 24)
                    }
                }
                .navigationTitle("Points Shop")
            }
        } else {
            // Fallback on earlier versions
        }
    }
}

#Preview {
    ShopView(viewModel: ShopViewModel(currentUser: User(id: "1", username: "Kenjo", points: 2500, currentStreak: 100, friendList: [], pendingFriendRequests: [], unlockedCustomizations: [])))
}
