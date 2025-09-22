//
//  AddGarmentView.swift
//  ClosetTwin
//
//  Created by David Gogoana on 22.09.2025.
//

import SwiftUI

struct AddGarmentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appSession: AppSession
    @State private var garment = Garment(
        name: "",
        category: .tshirt,
        intendedFit: "regular",
        measurements: GarmentMeasurements()
    )
    @State private var fabric = Fabric(stretchPercent: 0)
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    TextField("Garment Name", text: $garment.name)
                    
                    Picker("Category", selection: $garment.category) {
                        ForEach(GarmentCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                    
                    Picker("Intended Fit", selection: $garment.intendedFit) {
                        Text("Slim").tag("slim")
                        Text("Regular").tag("regular")
                        Text("Oversized").tag("oversized")
                    }
                    
                    if let brand = garment.brand {
                        TextField("Brand", text: Binding(
                            get: { brand },
                            set: { garment.brand = $0.isEmpty ? nil : $0 }
                        ))
                    } else {
                        TextField("Brand (optional)", text: Binding(
                            get: { "" },
                            set: { garment.brand = $0.isEmpty ? nil : $0 }
                        ))
                    }
                    
                    if let sku = garment.sku {
                        TextField("SKU", text: Binding(
                            get: { sku },
                            set: { garment.sku = $0.isEmpty ? nil : $0 }
                        ))
                    } else {
                        TextField("SKU (optional)", text: Binding(
                            get: { "" },
                            set: { garment.sku = $0.isEmpty ? nil : $0 }
                        ))
                    }
                }
                
                Section("Measurements (cm)") {
                    if garment.category.isTop {
                        HStack {
                            Text("Chest (flat)")
                            Spacer()
                            TextField("0", value: $garment.measurements.chestFlatCm, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        HStack {
                            Text("Waist (flat)")
                            Spacer()
                            TextField("0", value: $garment.measurements.waistFlatCm, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        HStack {
                            Text("Hip (flat)")
                            Spacer()
                            TextField("0", value: $garment.measurements.hipFlatCm, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        HStack {
                            Text("Shoulder")
                            Spacer()
                            TextField("0", value: $garment.measurements.shoulderCm, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        HStack {
                            Text("Sleeve")
                            Spacer()
                            TextField("0", value: $garment.measurements.sleeveCm, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                    } else {
                        HStack {
                            Text("Waist (flat)")
                            Spacer()
                            TextField("0", value: $garment.measurements.waistFlatCm, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        HStack {
                            Text("Hip (flat)")
                            Spacer()
                            TextField("0", value: $garment.measurements.hipFlatCm, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        HStack {
                            Text("Thigh (flat)")
                            Spacer()
                            TextField("0", value: $garment.measurements.thighFlatCm, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        HStack {
                            Text("Hem (flat)")
                            Spacer()
                            TextField("0", value: $garment.measurements.hemFlatCm, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        if garment.category == .jeans || garment.category == .trousers {
                            HStack {
                                Text("Rise Front")
                                Spacer()
                                TextField("0", value: $garment.measurements.riseFrontCm, format: .number)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                            }
                            
                            HStack {
                                Text("Rise Back")
                                Spacer()
                                TextField("0", value: $garment.measurements.riseBackCm, format: .number)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                    }
                    
                    HStack {
                        Text("Length")
                        Spacer()
                        TextField("0", value: $garment.measurements.lengthCm, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Fabric Properties") {
                    HStack {
                        Text("Stretch (%)")
                        Spacer()
                        TextField("0", value: $fabric.stretchPercent, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Weight (GSM)")
                        Spacer()
                        TextField("0", value: $fabric.weightGsm, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle("Add Garment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveGarment()
                    }
                    .disabled(garment.name.isEmpty || isSaving)
                }
            }
        }
    }
    
    private func saveGarment() {
        isSaving = true
        garment.fabric = fabric
        
        Task {
            await appSession.saveGarment(garment)
            
            await MainActor.run {
                isSaving = false
                dismiss()
            }
        }
    }
}

#Preview {
    AddGarmentView()
        .environmentObject(AppSession())
}
