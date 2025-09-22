//
//  ImportAvatarView.swift
//  ClosetTwin
//
//  Created by David Gogoana on 22.09.2025.
//

import SwiftUI

struct ImportAvatarView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appSession: AppSession
    @State private var inputToken = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingPreview = false
    @State private var importedData: (profile: SharedAvatarData, measurements: MeasurementSet)?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Instructions
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Import Avatar")
                            .font(AppTypography.title2)
                            .foregroundColor(AppColors.text)
                        
                        Text("Enter an avatar token or paste a ClosetTwin avatar link to import someone's measurements.")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.secondaryText)
                    }
                    
                    // Input Section
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Avatar Token or Link")
                            .font(AppTypography.subheadline)
                            .foregroundColor(AppColors.text)
                        
                        TextField("closettwin://avatar/ABC123 or ABC123", text: $inputToken)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    // Import Button
                    if isLoading {
                        LoadingView(message: "Importing avatar...")
                    } else {
                        PrimaryButton(title: "Import Avatar") {
                            importAvatar()
                        }
                        .disabled(inputToken.isEmpty)
                    }
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(AppTypography.caption)
                            .foregroundColor(.red)
                            .padding(AppSpacing.sm)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(AppCornerRadius.sm)
                    }
                    
                    // Info Section
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("How to get an avatar token:")
                            .font(AppTypography.subheadline)
                            .foregroundColor(AppColors.text)
                        
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            infoRow("1.", "Ask your friend to share their avatar from the Profile tab")
                            infoRow("2.", "They can send you the QR code or the share link")
                            infoRow("3.", "Paste the token or link here to import")
                        }
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.secondaryBackground)
                    .cornerRadius(AppCornerRadius.md)
                    
                    Spacer()
                }
                .padding(AppSpacing.md)
            }
            .navigationTitle("Import Avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingPreview) {
                if let importedData = importedData {
                    AvatarPreviewView(
                        profile: importedData.profile,
                        measurements: importedData.measurements
                    ) {
                        saveImportedAvatar()
                    }
                }
            }
        }
    }
    
    private func infoRow(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.xs) {
            Text(number)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.secondaryText)
            Text(text)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.secondaryText)
            Spacer()
        }
    }
    
    private func importAvatar() {
        isLoading = true
        errorMessage = nil
        
        // Extract token from input
        let token: String
        if inputToken.hasPrefix("closettwin://avatar/") {
            token = String(inputToken.dropFirst("closettwin://avatar/".count))
        } else {
            token = inputToken
        }
        
        Task {
            do {
                let cloudKitStore = CloudKitStore()
                let importedData = try await cloudKitStore.fetchSharedAvatar(token: token)
                
                await MainActor.run {
                    self.importedData = importedData
                    self.isLoading = false
                    self.showingPreview = true
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to import avatar: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func saveImportedAvatar() {
        guard let importedData = importedData else { return }
        
        Task {
            // Create a new measurement set from imported data
            var measurementSet = importedData.measurements
            measurementSet.name = "\(importedData.profile.displayName ?? "Friend")'s Measurements"
            measurementSet.createdAt = Date()
            
            await appSession.saveMeasurementSet(measurementSet)
            
            await MainActor.run {
                dismiss()
            }
        }
    }
}

struct AvatarPreviewView: View {
    let profile: SharedAvatarData
    let measurements: MeasurementSet
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // Profile Info
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Avatar Preview")
                            .font(AppTypography.title2)
                            .foregroundColor(AppColors.text)
                        
                        CardView {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                HStack {
                                    Circle()
                                        .fill(AppColors.primary.opacity(0.1))
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .foregroundColor(AppColors.primary)
                                        )
                                    
                                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                        Text(profile.displayName ?? "Unknown")
                                            .font(AppTypography.headline)
                                            .foregroundColor(AppColors.text)
                                        
                                        Text(profile.gender.rawValue.capitalized)
                                            .font(AppTypography.subheadline)
                                            .foregroundColor(AppColors.secondaryText)
                                    }
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                    
                    // Measurements Preview
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Measurements")
                            .font(AppTypography.title3)
                            .foregroundColor(AppColors.text)
                        
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            measurementRow("Height", "\(String(format: "%.1f", measurements.heightCm)) cm")
                            measurementRow("Chest/Bust", "\(String(format: "%.1f", measurements.chestBustCm)) cm")
                            measurementRow("Waist", "\(String(format: "%.1f", measurements.waistCm)) cm")
                            measurementRow("Hip", "\(String(format: "%.1f", measurements.highHipCm)) cm")
                            measurementRow("Shoulder", "\(String(format: "%.1f", measurements.shoulderWidthCm)) cm")
                        }
                        .padding(AppSpacing.md)
                        .background(AppColors.secondaryBackground)
                        .cornerRadius(AppCornerRadius.md)
                    }
                    
                    // Warning
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(AppColors.secondary)
                            Text("Important")
                                .font(AppTypography.subheadline)
                                .foregroundColor(AppColors.text)
                        }
                        
                        Text("This will create a new measurement set in your closet. It won't affect your existing measurements.")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.secondaryText)
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.secondary.opacity(0.1))
                    .cornerRadius(AppCornerRadius.md)
                    
                    Spacer()
                }
                .padding(AppSpacing.md)
            }
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Import") {
                        onSave()
                    }
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.primary)
                }
            }
        }
    }
    
    private func measurementRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.secondaryText)
            Spacer()
            Text(value)
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.text)
        }
    }
}

#Preview {
    ImportAvatarView()
        .environmentObject(AppSession())
}
