//
//  LoginView.swift
//  Larva
//
//  Created by student on 28/05/26.
//

import SwiftUI

/// The sign-in screen shown when the user is not authenticated.
///
/// Reads `authViewModel.isLoading` and `authViewModel.errorMessage` to show
/// inline feedback while the Firebase auth call is in-flight or after failure.
/// Navigation to `SignUpView` is handled via a `NavigationStack` destination.
struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    /// Controls whether the `SignUpView` is pushed onto the navigation stack.
    @State private var showSignUp = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "leaf.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.mint)
                    
                    Text("Welcome Back")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Move quietly. Earn softly.")
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
                        await authViewModel.login(email: email, password: password)
                    }
                } label: {
                    ZStack {
                        if authViewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Sign In")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .background(Color.mint)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(email.isEmpty || password.isEmpty || authViewModel.isLoading)
                
                Spacer()
                
                // Toggle to Sign Up
                Button {
                    showSignUp.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundColor(.secondary)
                        Text("Sign Up")
                            .fontWeight(.bold)
                            .foregroundColor(.mint)
                    }
                    .font(.footnote)
                }
            }
            .padding()
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
            }
        }
    }
}

#Preview {
    LoginView()
}
