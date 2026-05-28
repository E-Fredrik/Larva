//
//  AddFriendView.swift
//  LarvaDep
//
//  Created by Eko Nur Cahyo S on 27/05/26.
//

import SwiftUI

struct AddFriendView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: FriendViewModel
    @State private var friendCode: String = ""

    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                VStack(spacing: 24) {
                    HStack {
                        TextField("Enter Friend Code", text: $friendCode)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.allCharacters)

                        Button("Add") {
                            viewModel.sendFriendRequest(to: friendCode)
                            friendCode = ""
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.mint)
                        .disabled(friendCode.isEmpty)
                    }
                    .padding()

                    if !viewModel.pendingRequests.isEmpty {
                        VStack(alignment: .leading) {
                            Text("Pending Requests")
                                .font(.headline)
                                .padding(.horizontal)

                            List {
                                ForEach(viewModel.pendingRequests) { request in
                                    HStack {
                                        Text(request.username)
                                            .font(.subheadline)
                                        Spacer()
                                        Button(action: {
                                            viewModel.acceptRequest(
                                                from: request
                                            )
                                        }) {
                                            Image(
                                                systemName:
                                                    "checkmark.circle.fill"
                                            )
                                            .foregroundColor(.mint)
                                            .font(.title2)
                                        }
                                        .buttonStyle(.plain)

                                        Button(action: {
                                            viewModel.declineRequest(
                                                from: request
                                            )
                                        }) {
                                            Image(
                                                systemName: "xmark.circle.fill"
                                            )
                                            .foregroundColor(.red)
                                            .font(.title2)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .listStyle(.plain)
                        }
                    }

                    Spacer()

                    Text(
                        "Share your unique code with friends so they can add you to their leaderboard."
                    )
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.thinMaterial)
                    .cornerRadius(16)
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
                .navigationTitle("Add Friend")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }
}
