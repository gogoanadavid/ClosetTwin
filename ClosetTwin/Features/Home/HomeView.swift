//
//  HomeView.swift
//  ClosetTwin
//
//  Created by David Gogoana on 22.09.2025.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appSession: AppSession
    @State private var showingAddItem = false
    @State private var showingEditMeasurements = false
    @State private var showingShareAvatar = false
    @State private var showingScanQR = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Greeting Section
                    greetingSection
                    
                    // Measurement Set Picker
                    measurementSetPicker
                    
                    // Avatar Placeholder
                    AvatarPlaceholderView()
                    
                    // Action Buttons
                    actionButtons
                }
                .padding(AppSpacing.md)
            }
            .navigationTitle("ClosetTwin")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAddItem) {
                AddGarmentView()
            }
            .sheet(isPresented: $showingEditMeasurements) {
                if appSession.measurementSets.isEmpty {
                    OnboardingView()
                } else {
                    MeasurementSetsView()
                }
            }
            .sheet(isPresented: $showingShareAvatar) {
                ShareAvatarView()
            }
            .sheet(isPresented: $showingScanQR) {
                QRScanView()
            }
        }
    }
    
    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Hello, \(appSession.userProfile?.displayName ?? "there")!")
                        .font(AppTypography.title2)
                        .foregroundColor(AppColors.text)
                    
                    if let currentSet = appSession.currentMeasurementSet {
                        Text("Using: \(currentSet.name)")
                            .font(AppTypography.subheadline)
                            .foregroundColor(AppColors.secondaryText)
                    } else {
                        Text("No measurements set")
                            .font(AppTypography.subheadline)
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
                
                Spacer()
                
                // Profile avatar placeholder
                Circle()
                    .fill(AppColors.primary.opacity(0.1))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(AppColors.primary)
                    )
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.secondaryBackground)
        .cornerRadius(AppCornerRadius.md)
    }
    
    private var measurementSetPicker: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Active Measurements")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.text)
                
                Spacer()
                
                Button("Manage") {
                    showingEditMeasurements = true
                }
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.primary)
            }
            
            if appSession.measurementSets.isEmpty {
                VStack(spacing: AppSpacing.sm) {
                    Text("No measurement sets found")
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.secondaryText)
                    
                    Button("Add Your First Measurements") {
                        showingEditMeasurements = true
                    }
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(AppSpacing.md)
                .background(AppColors.tertiaryBackground)
                .cornerRadius(AppCornerRadius.sm)
            } else {
                Picker("Measurement Set", selection: Binding(
                    get: { appSession.currentMeasurementSet?.id ?? UUID() },
                    set: { id in
                        if let measurementSet = appSession.measurementSets.first(where: { $0.id == id }) {
                            Task {
                                await appSession.setCurrentMeasurementSet(measurementSet)
                            }
                        }
                    }
                )) {
                    ForEach(appSession.measurementSets) { measurementSet in
                        Text(measurementSet.name).tag(measurementSet.id)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(AppSpacing.sm)
                .background(AppColors.tertiaryBackground)
                .cornerRadius(AppCornerRadius.sm)
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.md) {
                PrimaryButton(title: "Add Item") {
                    showingAddItem = true
                }
                .frame(maxWidth: .infinity)
                
                PrimaryButton(title: "Scan QR") {
                    showingScanQR = true
                }
                .frame(maxWidth: .infinity)
            }
            
            HStack(spacing: AppSpacing.md) {
                SecondaryButton(title: "Edit Measurements") {
                    showingEditMeasurements = true
                }
                .frame(maxWidth: .infinity)
                
                SecondaryButton(title: "Share Avatar") {
                    showingShareAvatar = true
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AppSession())
}
