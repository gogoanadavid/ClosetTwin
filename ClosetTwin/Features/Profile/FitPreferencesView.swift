//
//  FitPreferencesView.swift
//  ClosetTwin
//
//  Created by David Gogoana on 22.09.2025.
//

import SwiftUI

struct FitPreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appSession: AppSession
    @State private var preferences: FitPreferences
    @State private var isSaving = false
    
    init() {
        self._preferences = State(initialValue: FitPreferences())
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Fit Style") {
                    Picker("Preferred Fit", selection: $preferences.preferredFit) {
                        Text("Slim").tag("slim")
                        Text("Regular").tag("regular")
                        Text("Oversized").tag("oversized")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section("Tightness Tolerance") {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        HStack {
                            Text("Tightness Tolerance")
                                .font(AppTypography.subheadline)
                                .foregroundColor(AppColors.text)
                            Spacer()
                            Text("\(String(format: "%.1f", preferences.tightnessToleranceCm)) cm")
                                .font(AppTypography.subheadline)
                                .foregroundColor(AppColors.secondaryText)
                        }
                        
                        Slider(
                            value: $preferences.tightnessToleranceCm,
                            in: 0...10,
                            step: 0.5
                        )
                        .accentColor(AppColors.primary)
                        
                        Text("How much tighter or looser than your preference you're willing to accept. Lower values mean you prefer a more precise fit.")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
                
                Section("Fit Analysis") {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("About Fit Analysis")
                            .font(AppTypography.subheadline)
                            .foregroundColor(AppColors.text)
                        
                        Text("ClosetTwin uses your preferences to provide personalized fit recommendations. The tightness tolerance affects how the app evaluates whether a garment will feel comfortable on you.")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.secondaryText)
                    }
                    .padding(.vertical, AppSpacing.sm)
                }
            }
            .navigationTitle("Fit Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePreferences()
                    }
                    .disabled(isSaving)
                }
            }
        }
        .onAppear {
            if let userProfile = appSession.userProfile {
                preferences = userProfile.preferences
            }
        }
    }
    
    private func savePreferences() {
        guard var userProfile = appSession.userProfile else { return }
        
        isSaving = true
        
        userProfile.preferences = preferences
        userProfile.updatedAt = Date()
        
        Task {
            do {
                // TODO: Use CloudKitStore when CloudKit is set up
                // let cloudKitStore = CloudKitStore()
                // try await cloudKitStore.saveUserProfile(userProfile)
                
                // For now, just update the app session
                print("Fit preferences saved (CloudKit disabled)")
                
                await MainActor.run {
                    appSession.userProfile = userProfile
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    // Handle error
                }
            }
        }
    }
}

#Preview {
    FitPreferencesView()
        .environmentObject(AppSession())
}
