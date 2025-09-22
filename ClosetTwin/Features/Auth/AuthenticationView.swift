//
//  AuthenticationView.swift
//  ClosetTwin
//
//  Created by David Gogoana on 22.09.2025.
//

import SwiftUI
import AuthenticationServices

struct AuthenticationView: View {
    @EnvironmentObject var appSession: AppSession
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.xl) {
                Spacer()
                
                // App Logo/Icon
                VStack(spacing: AppSpacing.lg) {
                    Image(systemName: "tshirt.fill")
                        .font(.system(size: 80))
                        .foregroundColor(AppColors.primary)
                    
                    Text("ClosetTwin")
                        .font(AppTypography.largeTitle)
                        .foregroundColor(AppColors.text)
                    
                    Text("Find your perfect fit")
                        .font(AppTypography.title3)
                        .foregroundColor(AppColors.secondaryText)
                }
                
                Spacer()
                
                // Features List
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    FeatureRow(icon: "ruler", title: "Body Measurements", description: "Track your measurements across different profiles")
                    FeatureRow(icon: "tshirt", title: "Fit Analysis", description: "Get detailed fit evaluations for any garment")
                    FeatureRow(icon: "qrcode", title: "QR Scanning", description: "Scan partner QR codes for instant measurements")
                    FeatureRow(icon: "person.2", title: "Share Avatars", description: "Share your measurements with friends and family")
                }
                .padding(.horizontal, AppSpacing.lg)
                
                Spacer()
                
                // Sign In Button
                VStack(spacing: AppSpacing.md) {
                    if appSession.isLoading {
                        LoadingView(message: "Signing in...")
                    } else {
                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = [.fullName, .email]
                        } onCompletion: { result in
                            switch result {
                            case .success(let authorization):
                                if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                                    Task {
                                        await handleAppleSignIn(appleIDCredential)
                                    }
                                }
                            case .failure(let error):
                                print("Sign in with Apple failed: \(error.localizedDescription)")
                            }
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 50)
                        .cornerRadius(AppCornerRadius.sm)
                        .padding(.horizontal, AppSpacing.lg)
                    }
                    
                    if let errorMessage = appSession.errorMessage {
                        Text(errorMessage)
                            .font(AppTypography.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, AppSpacing.lg)
                    }
                }
                
                Spacer()
            }
            .background(AppColors.background)
        }
    }
    
    private func handleAppleSignIn(_ credential: ASAuthorizationAppleIDCredential) async {
        appSession.signInWithApple()
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(AppColors.primary)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.text)
                
                Text(description)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .onAppear {
            print("AuthenticationView appeared")
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AppSession())
}
