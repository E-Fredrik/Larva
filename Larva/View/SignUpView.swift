//
//  SignUpView.swift
//  Larva
//
//  Created by student on 28/05/26.
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Join Larva")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Start tracking your progress today.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 32)
            
            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(.thinMaterial)
                    .cornerRadius(12)
                
                TextField("Username", text: $username)
                    .autocapitalization(.none)
                    .padding()
                    .background(.thinMaterial)
                    .cornerRadius(12)
                
                SecureField("Password", text: $password)
                    .padding()
                    .background(.thinMaterial)
                    .cornerRadius(12)
            }
            
            if !authViewModel.errorMessage.isEmpty {
                Text(authViewModel.errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                Task {
                    await authViewModel.signUp(email: email, password: password, username: username)
                }
            } label: {
                ZStack {
                    if authViewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Create Account")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .background(Color.mint)
            .foregroundColor(.white)
            .cornerRadius(12)
            .disabled(email.isEmpty || password.isEmpty || username.isEmpty || authViewModel.isLoading)
            
            Spacer()
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.mint)
                }
            }
        }
    }
}

#Preview {
    SignUpView()
}
