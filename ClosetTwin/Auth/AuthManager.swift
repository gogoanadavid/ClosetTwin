//
//  AuthManager.swift
//  ClosetTwin
//
//  Created by David Gogoana on 22.09.2025.
//

import Foundation
import AuthenticationServices
import CloudKit
import Combine

// MARK: - AuthManager
@MainActor
class AuthManager: NSObject, ObservableObject {
    @Published var isAuthenticated = false
    @Published var userProfile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // CloudKitStore will be initialized only when needed (after CloudKit is set up)
    private lazy var cloudKitStore = CloudKitStore()
    
    override init() {
        super.init()
        checkAuthenticationStatus()
    }
    
    // MARK: - Public Methods
    
    func signInWithApple() {
        isLoading = true
        errorMessage = nil
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    func signOut() {
        userProfile = nil
        isAuthenticated = false
        errorMessage = nil
    }
    
    // MARK: - Private Methods
    
    func checkAuthenticationStatus() {
        // For now, always show the authentication view
        // In a real app, you would check stored credentials here
        print("Checking authentication status - showing auth view")
        self.isAuthenticated = false
        self.userProfile = nil
    }
    
    private func loadStoredProfile() async -> UserProfile? {
        // In a real app, you'd store the Apple User ID in UserDefaults or Keychain
        // For now, we'll return nil and require fresh sign-in
        return nil
    }
    
    private func handleSuccessfulAuth(appleIDCredential: ASAuthorizationAppleIDCredential) async {
        guard let identityToken = appleIDCredential.identityToken,
              let identityTokenString = String(data: identityToken, encoding: .utf8) else {
            await MainActor.run {
                self.errorMessage = "Failed to get identity token"
                self.isLoading = false
            }
            return
        }
        
        let userIdentifier = appleIDCredential.user
        let fullName = appleIDCredential.fullName
        let email = appleIDCredential.email
        
        // Create display name from full name components
        let displayName = createDisplayName(from: fullName)
        
        do {
            // Check if user profile exists
            var profile = try await cloudKitStore.fetchUserProfile()
            
            if var existingProfile = profile {
                // Update existing profile if needed
                if let email = email, existingProfile.displayName == nil {
                    existingProfile.displayName = displayName
                    existingProfile.updatedAt = Date()
                    try await cloudKitStore.saveUserProfile(existingProfile)
                    profile = existingProfile
                }
            } else {
                // Create new profile
                let newProfile = UserProfile(
                    appleUserId: userIdentifier,
                    displayName: displayName,
                    gender: .unspecified,
                    preferences: FitPreferences()
                )
                
                try await cloudKitStore.saveUserProfile(newProfile)
                profile = newProfile
            }
            
            await MainActor.run {
                self.userProfile = profile
                self.isAuthenticated = true
                self.isLoading = false
                self.errorMessage = nil
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to save user profile: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    private func createDisplayName(from fullName: PersonNameComponents?) -> String? {
        guard let fullName = fullName else { return nil }
        
        var components: [String] = []
        
        if let givenName = fullName.givenName {
            components.append(givenName)
        }
        
        if let familyName = fullName.familyName {
            components.append(familyName)
        }
        
        return components.isEmpty ? nil : components.joined(separator: " ")
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AuthManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Task {
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                await handleSuccessfulAuth(appleIDCredential: appleIDCredential)
            } else {
                await MainActor.run {
                    self.errorMessage = "Unexpected authorization credential type"
                    self.isLoading = false
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Task { @MainActor in
            if let authError = error as? ASAuthorizationError {
                switch authError.code {
                case .canceled:
                    self.errorMessage = nil // User canceled, don't show error
                case .failed:
                    self.errorMessage = "Authentication failed"
                case .invalidResponse:
                    self.errorMessage = "Invalid response from Apple"
                case .notHandled:
                    self.errorMessage = "Authentication not handled"
                case .unknown:
                    self.errorMessage = "Unknown authentication error"
                @unknown default:
                    self.errorMessage = "Unknown authentication error"
                }
            } else {
                self.errorMessage = error.localizedDescription
            }
            
            self.isLoading = false
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AuthManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Return the main window
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window found")
        }
        return window
    }
}
