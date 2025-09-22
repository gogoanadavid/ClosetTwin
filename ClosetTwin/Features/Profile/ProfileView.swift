//
//  ProfileView.swift
//  ClosetTwin
//
//  Created by David Gogoana on 22.09.2025.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appSession: AppSession
    @State private var showingShareAvatar = false
    @State private var showingImportAvatar = false
    @State private var showingMeasurementSets = false
    @State private var showingFitPreferences = false
    
    var body: some View {
        NavigationView {
            List {
                // Profile Section
                profileSection
                
                // Measurements Section
                measurementsSection
                
                // Sharing Section
                sharingSection
                
                // Preferences Section
                preferencesSection
                
                // Account Section
                accountSection
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingShareAvatar) {
                ShareAvatarView()
            }
            .sheet(isPresented: $showingImportAvatar) {
                ImportAvatarView()
            }
            .sheet(isPresented: $showingMeasurementSets) {
                MeasurementSetsView()
            }
            .sheet(isPresented: $showingFitPreferences) {
                FitPreferencesView()
            }
        }
    }
    
    private var profileSection: some View {
        Section {
            HStack(spacing: AppSpacing.md) {
                // Profile Avatar
                Circle()
                    .fill(AppColors.primary.opacity(0.1))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(AppColors.primary)
                            .font(.title2)
                    )
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(appSession.userProfile?.displayName ?? "User")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.text)
                    
                    Text(appSession.userProfile?.gender.rawValue.capitalized ?? "Unspecified")
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.secondaryText)
                    
                    Text("\(appSession.measurementSets.count) measurement sets")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.tertiaryText)
                }
                
                Spacer()
            }
            .padding(.vertical, AppSpacing.sm)
        } header: {
            Text("Profile")
        }
    }
    
    private var measurementsSection: some View {
        Section {
            Button(action: { showingMeasurementSets = true }) {
                HStack {
                    Image(systemName: "ruler")
                        .foregroundColor(AppColors.primary)
                    Text("Manage Measurements")
                        .foregroundColor(AppColors.text)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppColors.tertiaryText)
                        .font(.caption)
                }
            }
            
            if let currentSet = appSession.currentMeasurementSet {
                Button(action: { showingMeasurementSets = true }) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(AppColors.comfy)
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("Active: \(currentSet.name)")
                                .font(AppTypography.subheadline)
                                .foregroundColor(AppColors.text)
                            Text("Created \(currentSet.createdAt, style: .date)")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.secondaryText)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(AppColors.tertiaryText)
                            .font(.caption)
                    }
                }
            }
        } header: {
            Text("Measurements")
        }
    }
    
    private var sharingSection: some View {
        Section {
            Button(action: { showingShareAvatar = true }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(AppColors.primary)
                    Text("Share Avatar")
                        .foregroundColor(AppColors.text)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppColors.tertiaryText)
                        .font(.caption)
                }
            }
            
            Button(action: { showingImportAvatar = true }) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundColor(AppColors.primary)
                    Text("Import Avatar")
                        .foregroundColor(AppColors.text)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppColors.tertiaryText)
                        .font(.caption)
                }
            }
            
            if appSession.userProfile?.sharedPublicToken != nil {
                HStack {
                    Image(systemName: "link")
                        .foregroundColor(AppColors.secondary)
                    Text("Avatar is shared")
                        .foregroundColor(AppColors.text)
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColors.comfy)
                }
            }
        } header: {
            Text("Sharing")
        }
    }
    
    private var preferencesSection: some View {
        Section {
            Button(action: { showingFitPreferences = true }) {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(AppColors.primary)
                    Text("Fit Preferences")
                        .foregroundColor(AppColors.text)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppColors.tertiaryText)
                        .font(.caption)
                }
            }
            
            HStack {
                Image(systemName: "person.2")
                    .foregroundColor(AppColors.secondary)
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Preferred Fit")
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.text)
                    Text(appSession.userProfile?.preferences.preferredFit.capitalized ?? "Regular")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondaryText)
                }
                Spacer()
            }
        } header: {
            Text("Preferences")
        }
    }
    
    private var accountSection: some View {
        Section {
            Button(action: { appSession.signOut() }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.red)
                    Text("Sign Out")
                        .foregroundColor(.red)
                    Spacer()
                }
            }
        } header: {
            Text("Account")
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppSession())
}
