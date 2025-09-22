//
//  ShareAvatarView.swift
//  ClosetTwin
//
//  Created by David Gogoana on 22.09.2025.
//

import SwiftUI

struct ShareAvatarView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appSession: AppSession
    @State private var qrCodeImage: UIImage?
    @State private var shareToken: String?
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    if isLoading {
                        LoadingView(message: "Generating share link...")
                    } else if let qrCodeImage = qrCodeImage, let token = shareToken {
                        shareContent(token: token, qrImage: qrCodeImage)
                    } else {
                        EmptyStateView(
                            icon: "square.and.arrow.up",
                            title: "Share Your Avatar",
                            message: "Generate a shareable link and QR code for your avatar so friends can buy you the perfect gifts.",
                            actionTitle: "Generate Link"
                        ) {
                            generateShareLink()
                        }
                    }
                }
                .padding(AppSpacing.md)
            }
            .navigationTitle("Share Avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func shareContent(token: String, qrImage: UIImage) -> some View {
        VStack(spacing: AppSpacing.lg) {
            // QR Code
            Image(uiImage: qrImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 200)
                .background(Color.white)
                .cornerRadius(AppCornerRadius.md)
            
            // Share Link
            VStack(spacing: AppSpacing.sm) {
                Text("Share Link")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.text)
                
                Text("closettwin://avatar/\(token)")
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.secondaryText)
                    .padding(AppSpacing.sm)
                    .background(AppColors.tertiaryBackground)
                    .cornerRadius(AppCornerRadius.sm)
            }
            
            // Share Buttons
            VStack(spacing: AppSpacing.md) {
                Button(action: { copyToClipboard(token) }) {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text("Copy Link")
                    }
                    .font(AppTypography.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(AppColors.primary)
                    .cornerRadius(AppCornerRadius.sm)
                }
                
                ShareLink(item: URL(string: "closettwin://avatar/\(token)")!) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(AppColors.primary.opacity(0.1))
                    .cornerRadius(AppCornerRadius.sm)
                }
            }
            
            // Info
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("How it works:")
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.text)
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    infoRow("•", "Friends can scan the QR code or use the link")
                    infoRow("•", "They'll see your avatar measurements (read-only)")
                    infoRow("•", "Perfect for gift shopping and sizing")
                    infoRow("•", "You can revoke access anytime")
                }
            }
            .padding(AppSpacing.md)
            .background(AppColors.secondaryBackground)
            .cornerRadius(AppCornerRadius.md)
        }
    }
    
    private func infoRow(_ bullet: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.xs) {
            Text(bullet)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.secondaryText)
            Text(text)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.secondaryText)
            Spacer()
        }
    }
    
    private func generateShareLink() {
        guard let profile = appSession.userProfile,
              let currentMeasurementSet = appSession.currentMeasurementSet else {
            return
        }
        
        isLoading = true
        
        Task {
            // Generate a unique token
            let token = generateUniqueToken()
            
                // Save shared avatar to CloudKit
            do {
                // TODO: Use CloudKitStore when CloudKit is set up
                // let cloudKitStore = CloudKitStore()
                // try await cloudKitStore.saveSharedAvatar(
                //     token: token,
                //     profile: profile,
                //     measurementSet: currentMeasurementSet
                // )

                // Update user profile with share token
                var updatedProfile = profile
                updatedProfile.sharedPublicToken = token
                updatedProfile.updatedAt = Date()
                // try await cloudKitStore.saveUserProfile(updatedProfile)
                
                print("Avatar sharing (CloudKit disabled) - Token: \(token)")
                
                // Generate QR code
                let qrImage = QRGenerator.generateAvatarQRCode(token: token)
                
                await MainActor.run {
                    self.shareToken = token
                    self.qrCodeImage = qrImage
                    self.isLoading = false
                }
                
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    // Handle error
                }
            }
        }
    }
    
    private func copyToClipboard(_ token: String) {
        UIPasteboard.general.string = "closettwin://avatar/\(token)"
        // Show success feedback
    }
    
    private func generateUniqueToken() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        return String((0..<8).map { _ in characters.randomElement()! })
    }
}

#Preview {
    ShareAvatarView()
        .environmentObject(AppSession())
}
