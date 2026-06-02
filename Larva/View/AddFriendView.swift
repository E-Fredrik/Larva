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
        NavigationStack {
            VStack(spacing: 24) {
                Text("Enter Friend Code")
                    .font(.title2).fontWeight(.bold)
                
                TextField("Code (e.g. ABC123)", text: $friendCode)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.allCharacters)
                    .padding(.horizontal, 32)
                
                Button(action: {
                    Task { await viewModel.sendFriendRequest(to: friendCode) }
                }) {
                    Text("Send Request")
                        .foregroundColor(.white).padding().frame(maxWidth: .infinity)
                        .background(Color.mint).cornerRadius(12).padding(.horizontal, 32)
                }
                Spacer()
            }
            .padding(.top, 40)
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Friend Request", isPresented: $viewModel.showAlert) {
                Button("OK", role: .cancel) {
                    if viewModel.alertMessage.contains("successfully") {
                        dismiss()
                    }
                }
            } message: {
                Text(viewModel.alertMessage)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
