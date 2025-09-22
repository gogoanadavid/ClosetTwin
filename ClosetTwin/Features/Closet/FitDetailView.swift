//
//  FitDetailView.swift
//  ClosetTwin
//
//  Created by David Gogoana on 22.09.2025.
//

import SwiftUI

struct FitDetailView: View {
    let garment: Garment
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appSession: AppSession
    @State private var selectedMode: FitMode = .basic
    @State private var fitResult: FitResult?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // Garment Info
                    garmentInfoSection
                    
                    // Mode Selection
                    modeSelectionSection
                    
                    // Measurement Set Selection
                    measurementSetSection
                    
                    // Fit Results
                    if let fitResult = fitResult {
                        fitResultsSection(fitResult)
                    } else {
                        evaluateButton
                    }
                }
                .padding(AppSpacing.md)
            }
            .navigationTitle("Fit Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                evaluateFit()
            }
        }
    }
    
    private var garmentInfoSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(garment.name)
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.text)
                
                if let brand = garment.brand {
                    Text(brand)
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.secondaryText)
                }
                
                HStack {
                    Text(garment.category.displayName)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.text)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xs)
                        .background(AppColors.primary.opacity(0.1))
                        .cornerRadius(AppCornerRadius.sm)
                    
                    Text(garment.intendedFit.capitalized)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.text)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xs)
                        .background(AppColors.secondary.opacity(0.1))
                        .cornerRadius(AppCornerRadius.sm)
                }
            }
        }
    }
    
    private var modeSelectionSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Analysis Mode")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.text)
            
            Picker("Mode", selection: $selectedMode) {
                Text("Basic").tag(FitMode.basic)
                Text("Advanced").tag(FitMode.advanced)
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: selectedMode) { _, _ in
                evaluateFit()
            }
        }
    }
    
    private var measurementSetSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Measurement Set")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.text)
            
            if appSession.measurementSets.isEmpty {
                Text("No measurement sets available")
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.secondaryText)
                    .padding(AppSpacing.md)
                    .frame(maxWidth: .infinity)
                    .background(AppColors.tertiaryBackground)
                    .cornerRadius(AppCornerRadius.sm)
            } else {
                Picker("Measurement Set", selection: Binding(
                    get: { appSession.currentMeasurementSet?.id ?? UUID() },
                    set: { id in
                        if let measurementSet = appSession.measurementSets.first(where: { $0.id == id }) {
                            Task {
                                await appSession.setCurrentMeasurementSet(measurementSet)
                                evaluateFit()
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
                .background(AppColors.secondaryBackground)
                .cornerRadius(AppCornerRadius.sm)
            }
        }
    }
    
    private var evaluateButton: some View {
        Button("Evaluate Fit") {
            evaluateFit()
        }
        .font(AppTypography.headline)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.md)
        .background(AppColors.primary)
        .cornerRadius(AppCornerRadius.sm)
    }
    
    private func fitResultsSection(_ fitResult: FitResult) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Fit Analysis Results")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.text)
            
            // Overall Rating
            CardView {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack {
                        Text("Overall Fit")
                            .font(AppTypography.subheadline)
                            .foregroundColor(AppColors.secondaryText)
                        Spacer()
                        FitRatingBadge(rating: fitResult.overall)
                    }
                    
                    if let percent = fitResult.sizeMatchPercent {
                        HStack {
                            Text("Size Match")
                                .font(AppTypography.subheadline)
                                .foregroundColor(AppColors.secondaryText)
                            Spacer()
                            Text("\(percent)%")
                                .font(AppTypography.subheadline)
                                .foregroundColor(AppColors.text)
                        }
                    }
                    
                    Text(fitResult.summary)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondaryText)
                        .padding(.top, AppSpacing.xs)
                }
            }
            
            // Zone Results
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Zone Analysis")
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.text)
                
                ForEach(fitResult.zones, id: \.zone) { zone in
                    zoneResultRow(zone)
                }
            }
            .padding(AppSpacing.md)
            .background(AppColors.secondaryBackground)
            .cornerRadius(AppCornerRadius.md)
        }
    }
    
    private func zoneResultRow(_ zone: FitZoneResult) -> some View {
        HStack {
            Text(zone.zone.capitalized)
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.text)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                FitRatingBadge(rating: zone.rating)
                
                Text("\(String(format: "%.1f", zone.deltaCm)) cm")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.secondaryText)
                
                if let strain = zone.strain {
                    Text("Strain: \(String(format: "%.2f", strain))")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.tertiaryText)
                }
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }
    
    private func evaluateFit() {
        guard appSession.currentMeasurementSet != nil else {
            fitResult = nil
            return
        }
        
        fitResult = appSession.evaluateFit(garment: garment, mode: selectedMode)
    }
}

#Preview {
    FitDetailView(garment: Garment(
        name: "Sample T-Shirt",
        category: .tshirt,
        intendedFit: "regular",
        measurements: GarmentMeasurements(
            chestFlatCm: 50,
            waistFlatCm: 45,
            lengthCm: 70
        )
    ))
    .environmentObject(AppSession())
}
