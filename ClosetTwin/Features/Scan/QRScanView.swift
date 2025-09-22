//
//  QRScanView.swift
//  ClosetTwin
//
//  Created by David Gogoana on 22.09.2025.
//

import SwiftUI
import AVFoundation

struct QRScanView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appSession: AppSession
    @StateObject private var qrScanner = QRScanner()
    @State private var scannedCode: String?
    @State private var showingGarmentPreview = false
    @State private var scannedGarment: Garment?
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                if qrScanner.isScanning {
                    cameraView
                } else {
                    instructionView
                }
                
                // Overlay UI
                VStack {
                    Spacer()
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(AppTypography.subheadline)
                            .foregroundColor(.white)
                            .padding(AppSpacing.md)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(AppCornerRadius.sm)
                            .padding(AppSpacing.md)
                    }
                }
            }
            .navigationTitle("Scan QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(qrScanner.isScanning ? "Stop" : "Start") {
                        if qrScanner.isScanning {
                            qrScanner.stopScanning()
                        } else {
                            qrScanner.startScanning()
                        }
                    }
                }
            }
            .onAppear {
                setupScanner()
                qrScanner.startScanning()
            }
            .onDisappear {
                qrScanner.stopScanning()
            }
            .sheet(isPresented: $showingGarmentPreview) {
                if let garment = scannedGarment {
                    GarmentPreviewView(garment: garment) {
                        // Save garment
                        Task {
                            await appSession.saveGarment(garment)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
    
    private var cameraView: some View {
        CameraPreviewView(scanner: qrScanner)
            .ignoresSafeArea()
    }
    
    private var instructionView: some View {
        VStack(spacing: AppSpacing.xl) {
            Image(systemName: "qrcode.viewfinder")
                .font(.system(size: 80))
                .foregroundColor(AppColors.secondaryText)
            
            VStack(spacing: AppSpacing.md) {
                Text("Scan Partner QR Code")
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.text)
                
                Text("Point your camera at a partner's QR code to automatically add garment measurements to your closet.")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.lg)
            }
            
            Button("Start Scanning") {
                qrScanner.startScanning()
            }
            .font(AppTypography.headline)
            .foregroundColor(.white)
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.md)
            .background(AppColors.primary)
            .cornerRadius(AppCornerRadius.sm)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
    
    private func setupScanner() {
        qrScanner.onCodeScanned = { code in
            handleScannedCode(code)
        }
    }
    
    private func handleScannedCode(_ code: String) {
        let qrType = QRParser.parseQRCode(code)
        
        switch qrType {
        case .garment(let payload):
            let garment = payload.toGarment()
            scannedGarment = garment
            showingGarmentPreview = true
            errorMessage = nil
            
        case .avatar(let urlString):
            errorMessage = "Avatar QR codes are not supported in this view. Use the Profile tab to import avatars."
            
        case .unknown:
            errorMessage = "Invalid QR code format. Please scan a valid partner garment QR code."
        }
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let scanner: QRScanner
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        
        if let previewLayer = scanner.getPreviewLayer() {
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = scanner.getPreviewLayer() {
            previewLayer.frame = uiView.bounds
        }
    }
}

struct GarmentPreviewView: View {
    let garment: Garment
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // Garment Info
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Scanned Garment")
                            .font(AppTypography.title2)
                            .foregroundColor(AppColors.text)
                        
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            HStack {
                                Text("Name:")
                                    .font(AppTypography.subheadline)
                                    .foregroundColor(AppColors.secondaryText)
                                Spacer()
                                Text(garment.name)
                                    .font(AppTypography.subheadline)
                                    .foregroundColor(AppColors.text)
                            }
                            
                            if let brand = garment.brand {
                                HStack {
                                    Text("Brand:")
                                        .font(AppTypography.subheadline)
                                        .foregroundColor(AppColors.secondaryText)
                                    Spacer()
                                    Text(brand)
                                        .font(AppTypography.subheadline)
                                        .foregroundColor(AppColors.text)
                                }
                            }
                            
                            HStack {
                                Text("Category:")
                                    .font(AppTypography.subheadline)
                                    .foregroundColor(AppColors.secondaryText)
                                Spacer()
                                Text(garment.category.displayName)
                                    .font(AppTypography.subheadline)
                                    .foregroundColor(AppColors.text)
                            }
                            
                            HStack {
                                Text("Intended Fit:")
                                    .font(AppTypography.subheadline)
                                    .foregroundColor(AppColors.secondaryText)
                                Spacer()
                                Text(garment.intendedFit.capitalized)
                                    .font(AppTypography.subheadline)
                                    .foregroundColor(AppColors.text)
                            }
                        }
                        .padding(AppSpacing.md)
                        .background(AppColors.secondaryBackground)
                        .cornerRadius(AppCornerRadius.md)
                    }
                    
                    // Measurements
                    if hasMeasurements(garment.measurements) {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("Measurements")
                                .font(AppTypography.title3)
                                .foregroundColor(AppColors.text)
                            
                            measurementsView
                        }
                    }
                    
                    // Fabric Info
                    if let fabric = garment.fabric {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("Fabric Properties")
                                .font(AppTypography.title3)
                                .foregroundColor(AppColors.text)
                            
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                HStack {
                                    Text("Stretch:")
                                        .font(AppTypography.subheadline)
                                        .foregroundColor(AppColors.secondaryText)
                                    Spacer()
                                    Text("\(String(format: "%.1f", fabric.stretchPercent))%")
                                        .font(AppTypography.subheadline)
                                        .foregroundColor(AppColors.text)
                                }
                                
                                if let weight = fabric.weightGsm {
                                    HStack {
                                        Text("Weight:")
                                            .font(AppTypography.subheadline)
                                            .foregroundColor(AppColors.secondaryText)
                                        Spacer()
                                        Text("\(String(format: "%.0f", weight)) GSM")
                                            .font(AppTypography.subheadline)
                                            .foregroundColor(AppColors.text)
                                    }
                                }
                            }
                            .padding(AppSpacing.md)
                            .background(AppColors.secondaryBackground)
                            .cornerRadius(AppCornerRadius.md)
                        }
                    }
                    
                    Spacer(minLength: AppSpacing.xl)
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
                    Button("Save") {
                        onSave()
                    }
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.primary)
                }
            }
        }
    }
    
    private var measurementsView: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            if let chest = garment.measurements.chestFlatCm {
                measurementRow("Chest (flat)", "\(String(format: "%.1f", chest)) cm")
            }
            
            if let waist = garment.measurements.waistFlatCm {
                measurementRow("Waist (flat)", "\(String(format: "%.1f", waist)) cm")
            }
            
            if let hip = garment.measurements.hipFlatCm {
                measurementRow("Hip (flat)", "\(String(format: "%.1f", hip)) cm")
            }
            
            if let shoulder = garment.measurements.shoulderCm {
                measurementRow("Shoulder", "\(String(format: "%.1f", shoulder)) cm")
            }
            
            if let sleeve = garment.measurements.sleeveCm {
                measurementRow("Sleeve", "\(String(format: "%.1f", sleeve)) cm")
            }
            
            if let length = garment.measurements.lengthCm {
                measurementRow("Length", "\(String(format: "%.1f", length)) cm")
            }
            
            if let thigh = garment.measurements.thighFlatCm {
                measurementRow("Thigh (flat)", "\(String(format: "%.1f", thigh)) cm")
            }
            
            if let hem = garment.measurements.hemFlatCm {
                measurementRow("Hem (flat)", "\(String(format: "%.1f", hem)) cm")
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.secondaryBackground)
        .cornerRadius(AppCornerRadius.md)
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
    
    private func hasMeasurements(_ measurements: GarmentMeasurements) -> Bool {
        return measurements.chestFlatCm != nil ||
               measurements.waistFlatCm != nil ||
               measurements.hipFlatCm != nil ||
               measurements.shoulderCm != nil ||
               measurements.sleeveCm != nil ||
               measurements.lengthCm != nil ||
               measurements.thighFlatCm != nil ||
               measurements.hemFlatCm != nil ||
               measurements.chestCircumferenceCm != nil ||
               measurements.waistCircumferenceCm != nil ||
               measurements.hipCircumferenceCm != nil
    }
}

#Preview {
    QRScanView()
        .environmentObject(AppSession())
}
