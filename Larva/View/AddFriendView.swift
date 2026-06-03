//
//  AddFriendView.swift
//  Larva
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
                    .disableAutocorrection(true)
                    .padding(.horizontal, 32)
                
                Button(action: {
                    // 1. FORCE KEYBOARD TO CLOSE IMMEDIATELY
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    
                    // 2. WAIT 0.3s for the keyboard to vanish before hitting Firebase
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        viewModel.sendFriendRequest(to: friendCode) // No longer needs 'await'
                    }
                }) {
                    HStack {
                        if viewModel.isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.trailing, 8)
                        }
                        Text(viewModel.isProcessing ? "Processing..." : "Send Request")
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(friendCode.isEmpty || viewModel.isProcessing ? Color.gray : Color.mint)
                    .cornerRadius(12)
                    .padding(.horizontal, 32)
                }
                .disabled(friendCode.isEmpty || viewModel.isProcessing)
                
                Spacer()
            }
            .padding(.top, 40)
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Friend Request", isPresented: $viewModel.showAlert) {
                Button("OK", role: .cancel) {
                    if viewModel.alertMessage.contains("successfully") || viewModel.alertMessage.contains("sent to") {
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
