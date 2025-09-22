//
//  OnboardingView.swift
//  ClosetTwin
//
//  Created by David Gogoana on 22.09.2025.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appSession: AppSession
    @State private var measurementSet = MeasurementSet(
        name: "My Measurements",
        heightCm: 170.0,
        chestBustCm: 90.0,
        underbustCm: 80.0,
        waistCm: 75.0,
        highHipCm: 95.0,
        lowHipSeatCm: 100.0,
        shoulderWidthCm: 45.0,
        armLengthCm: 60.0,
        bicepCm: 30.0,
        inseamCm: 80.0,
        thighCm: 55.0,
        calfCm: 35.0
    )
    @State private var currentStep = 0
    @State private var isSaving = false
    
    private let steps = ["Basic Info", "Body Measurements", "Review"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.lg) {
                // Progress Indicator
                ProgressView(value: Double(currentStep + 1), total: Double(steps.count))
                    .progressViewStyle(LinearProgressViewStyle(tint: AppColors.primary))
                    .padding(.horizontal, AppSpacing.lg)
                
                // Step Content
                TabView(selection: $currentStep) {
                    basicInfoStep
                        .tag(0)
                    
                    measurementsStep
                        .tag(1)
                    
                    reviewStep
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Navigation Buttons
                HStack(spacing: AppSpacing.md) {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.primary)
                    }
                    
                    Spacer()
                    
                    Button(currentStep == steps.count - 1 ? "Complete" : "Next") {
                        if currentStep == steps.count - 1 {
                            saveMeasurements()
                        } else {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                    }
                    .font(AppTypography.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.sm)
                    .background(AppColors.primary)
                    .cornerRadius(AppCornerRadius.sm)
                    .disabled(isSaving)
                }
                .padding(.horizontal, AppSpacing.lg)
            }
            .navigationTitle("Setup Measurements")
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
    
    private var basicInfoStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text("Let's get started!")
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.text)
                
                Text("First, tell us a bit about yourself and give your measurement set a name.")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.secondaryText)
                
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Measurement Set Name")
                            .font(AppTypography.subheadline)
                            .foregroundColor(AppColors.text)
                        
                        TextField("e.g., Everyday, Gym, etc.", text: $measurementSet.name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Gender (optional)")
                            .font(AppTypography.subheadline)
                            .foregroundColor(AppColors.text)
                        
                        Picker("Gender", selection: $measurementSet.gender) {
                            ForEach(Gender.allCases, id: \.self) { gender in
                                Text(gender.rawValue.capitalized).tag(gender)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                
                Spacer()
            }
            .padding(AppSpacing.lg)
        }
    }
    
    private var measurementsStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text("Body Measurements")
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.text)
                
                Text("Enter your body measurements in centimeters. Don't worry if you don't have all measurements - you can update them later.")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.secondaryText)
                
                VStack(spacing: AppSpacing.md) {
                    MeasurementInputField(
                        title: "Height",
                        value: $measurementSet.heightCm,
                        unit: "cm",
                        range: 100...250,
                        helpText: "Your total height from head to toe"
                    )
                    
                    MeasurementInputField(
                        title: "Chest/Bust",
                        value: $measurementSet.chestBustCm,
                        unit: "cm",
                        range: 60...150,
                        helpText: "Circumference around the fullest part of your chest"
                    )
                    
                    MeasurementInputField(
                        title: "Underbust",
                        value: $measurementSet.underbustCm,
                        unit: "cm",
                        range: 50...140,
                        helpText: "Circumference directly under your bust"
                    )
                    
                    MeasurementInputField(
                        title: "Waist",
                        value: $measurementSet.waistCm,
                        unit: "cm",
                        range: 50...140,
                        helpText: "Circumference at the narrowest part of your waist"
                    )
                    
                    MeasurementInputField(
                        title: "High Hip",
                        value: $measurementSet.highHipCm,
                        unit: "cm",
                        range: 60...150,
                        helpText: "Circumference around your hips at the widest point"
                    )
                    
                    MeasurementInputField(
                        title: "Low Hip/Seat",
                        value: $measurementSet.lowHipSeatCm,
                        unit: "cm",
                        range: 60...150,
                        helpText: "Circumference around your seat at the fullest point"
                    )
                    
                    MeasurementInputField(
                        title: "Shoulder Width",
                        value: $measurementSet.shoulderWidthCm,
                        unit: "cm",
                        range: 30...70,
                        helpText: "Width from shoulder tip to shoulder tip"
                    )
                    
                    MeasurementInputField(
                        title: "Arm Length",
                        value: $measurementSet.armLengthCm,
                        unit: "cm",
                        range: 40...80,
                        helpText: "Length from shoulder tip to wrist"
                    )
                    
                    MeasurementInputField(
                        title: "Bicep",
                        value: $measurementSet.bicepCm,
                        unit: "cm",
                        range: 15...50,
                        helpText: "Circumference around your bicep at the fullest point"
                    )
                    
                    MeasurementInputField(
                        title: "Inseam",
                        value: $measurementSet.inseamCm,
                        unit: "cm",
                        range: 50...100,
                        helpText: "Length from crotch to ankle"
                    )
                    
                    MeasurementInputField(
                        title: "Thigh",
                        value: $measurementSet.thighCm,
                        unit: "cm",
                        range: 30...80,
                        helpText: "Circumference around your thigh at the fullest point"
                    )
                    
                    MeasurementInputField(
                        title: "Calf",
                        value: $measurementSet.calfCm,
                        unit: "cm",
                        range: 20...50,
                        helpText: "Circumference around your calf at the fullest point"
                    )
                }
                
                Spacer()
            }
            .padding(AppSpacing.lg)
        }
    }
    
    private var reviewStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text("Review Your Measurements")
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.text)
                
                Text("Please review your measurements before saving. You can always edit these later.")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.secondaryText)
                
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("\(measurementSet.name)")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.text)
                    
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        measurementRow("Height", "\(String(format: "%.1f", measurementSet.heightCm)) cm")
                        measurementRow("Chest/Bust", "\(String(format: "%.1f", measurementSet.chestBustCm)) cm")
                        measurementRow("Underbust", "\(String(format: "%.1f", measurementSet.underbustCm)) cm")
                        measurementRow("Waist", "\(String(format: "%.1f", measurementSet.waistCm)) cm")
                        measurementRow("High Hip", "\(String(format: "%.1f", measurementSet.highHipCm)) cm")
                        measurementRow("Low Hip/Seat", "\(String(format: "%.1f", measurementSet.lowHipSeatCm)) cm")
                        measurementRow("Shoulder Width", "\(String(format: "%.1f", measurementSet.shoulderWidthCm)) cm")
                        measurementRow("Arm Length", "\(String(format: "%.1f", measurementSet.armLengthCm)) cm")
                        measurementRow("Bicep", "\(String(format: "%.1f", measurementSet.bicepCm)) cm")
                        measurementRow("Inseam", "\(String(format: "%.1f", measurementSet.inseamCm)) cm")
                        measurementRow("Thigh", "\(String(format: "%.1f", measurementSet.thighCm)) cm")
                        measurementRow("Calf", "\(String(format: "%.1f", measurementSet.calfCm)) cm")
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.secondaryBackground)
                    .cornerRadius(AppCornerRadius.md)
                }
                
                Spacer()
            }
            .padding(AppSpacing.lg)
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
    
    private func saveMeasurements() {
        isSaving = true
        
        Task {
            await appSession.saveMeasurementSet(measurementSet)
            
            await MainActor.run {
                isSaving = false
                dismiss()
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppSession())
}
