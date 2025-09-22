//
//  MeasurementSetsView.swift
//  ClosetTwin
//
//  Created by David Gogoana on 22.09.2025.
//

import SwiftUI

struct MeasurementSetsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appSession: AppSession
    @State private var showingAddMeasurement = false
    @State private var editingMeasurementSet: MeasurementSet?
    
    var body: some View {
        NavigationView {
            Group {
                if appSession.measurementSets.isEmpty {
                    EmptyStateView(
                        icon: "ruler",
                        title: "No Measurement Sets",
                        message: "Create your first measurement set to start using ClosetTwin.",
                        actionTitle: "Add Measurements"
                    ) {
                        showingAddMeasurement = true
                    }
                } else {
                    measurementSetsList
                }
            }
            .navigationTitle("Measurement Sets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        showingAddMeasurement = true
                    }
                }
            }
            .sheet(isPresented: $showingAddMeasurement) {
                OnboardingView()
            }
            .sheet(item: $editingMeasurementSet) { measurementSet in
                EditMeasurementSetView(measurementSet: measurementSet)
            }
        }
    }
    
    private var measurementSetsList: some View {
        List {
            ForEach(appSession.measurementSets) { measurementSet in
                MeasurementSetRow(
                    measurementSet: measurementSet,
                    isActive: measurementSet.id == appSession.currentMeasurementSet?.id,
                    onEdit: { editingMeasurementSet = measurementSet },
                    onSetActive: {
                        Task {
                            await appSession.setCurrentMeasurementSet(measurementSet)
                        }
                    },
                    onDelete: {
                        Task {
                            await appSession.deleteMeasurementSet(measurementSet)
                        }
                    }
                )
            }
        }
    }
}

struct MeasurementSetRow: View {
    let measurementSet: MeasurementSet
    let isActive: Bool
    let onEdit: () -> Void
    let onSetActive: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Active indicator
            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppColors.comfy)
                    .font(.title2)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(AppColors.tertiaryText)
                    .font(.title2)
            }
            
            // Measurement set info
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(measurementSet.name)
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.text)
                
                Text("Created \(measurementSet.createdAt, style: .date)")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.secondaryText)
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: AppSpacing.sm) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(AppColors.primary)
                }
                
                if !isActive {
                    Button(action: onSetActive) {
                        Text("Set Active")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.primary)
                    }
                }
                
                Button(action: { showingDeleteAlert = true }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, AppSpacing.xs)
        .alert("Delete Measurement Set", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete '\(measurementSet.name)'? This action cannot be undone.")
        }
    }
}

struct EditMeasurementSetView: View {
    let measurementSet: MeasurementSet
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appSession: AppSession
    @State private var editedMeasurementSet: MeasurementSet
    @State private var isSaving = false
    
    init(measurementSet: MeasurementSet) {
        self.measurementSet = measurementSet
        self._editedMeasurementSet = State(initialValue: measurementSet)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Basic Info
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Basic Information")
                            .font(AppTypography.title3)
                            .foregroundColor(AppColors.text)
                        
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("Name")
                                .font(AppTypography.subheadline)
                                .foregroundColor(AppColors.text)
                            
                            TextField("Measurement set name", text: $editedMeasurementSet.name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    
                    // Measurements
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Measurements")
                            .font(AppTypography.title3)
                            .foregroundColor(AppColors.text)
                        
                        VStack(spacing: AppSpacing.md) {
                            MeasurementInputField(
                                title: "Height",
                                value: $editedMeasurementSet.heightCm,
                                unit: "cm",
                                range: 100...250,
                                helpText: "Your total height from head to toe"
                            )
                            
                            MeasurementInputField(
                                title: "Chest/Bust",
                                value: $editedMeasurementSet.chestBustCm,
                                unit: "cm",
                                range: 60...150,
                                helpText: "Circumference around the fullest part of your chest"
                            )
                            
                            MeasurementInputField(
                                title: "Waist",
                                value: $editedMeasurementSet.waistCm,
                                unit: "cm",
                                range: 50...140,
                                helpText: "Circumference at the narrowest part of your waist"
                            )
                            
                            MeasurementInputField(
                                title: "High Hip",
                                value: $editedMeasurementSet.highHipCm,
                                unit: "cm",
                                range: 60...150,
                                helpText: "Circumference around your hips at the widest point"
                            )
                            
                            MeasurementInputField(
                                title: "Shoulder Width",
                                value: $editedMeasurementSet.shoulderWidthCm,
                                unit: "cm",
                                range: 30...70,
                                helpText: "Width from shoulder tip to shoulder tip"
                            )
                            
                            MeasurementInputField(
                                title: "Arm Length",
                                value: $editedMeasurementSet.armLengthCm,
                                unit: "cm",
                                range: 40...80,
                                helpText: "Length from shoulder tip to wrist"
                            )
                            
                            MeasurementInputField(
                                title: "Inseam",
                                value: $editedMeasurementSet.inseamCm,
                                unit: "cm",
                                range: 50...100,
                                helpText: "Length from crotch to ankle"
                            )
                        }
                    }
                }
                .padding(AppSpacing.lg)
            }
            .navigationTitle("Edit Measurements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(isSaving)
                }
            }
        }
    }
    
    private func saveChanges() {
        isSaving = true
        
        Task {
            await appSession.saveMeasurementSet(editedMeasurementSet)
            
            await MainActor.run {
                isSaving = false
                dismiss()
            }
        }
    }
}

#Preview {
    MeasurementSetsView()
        .environmentObject(AppSession())
}
