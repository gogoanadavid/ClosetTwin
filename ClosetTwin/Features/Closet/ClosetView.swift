//
//  ClosetView.swift
//  ClosetTwin
//
//  Created by David Gogoana on 22.09.2025.
//

import SwiftUI

struct ClosetView: View {
    @EnvironmentObject var appSession: AppSession
    @State private var showingAddGarment = false
    @State private var selectedGarment: Garment?
    @State private var showingFitDetail = false
    
    var body: some View {
        NavigationView {
            Group {
                if appSession.garments.isEmpty {
                    EmptyStateView(
                        icon: "tshirt",
                        title: "Your Closet is Empty",
                        message: "Add garments to start evaluating fit and building your digital wardrobe.",
                        actionTitle: "Add First Garment"
                    ) {
                        showingAddGarment = true
                    }
                } else {
                    garmentGrid
                }
            }
            .navigationTitle("Closet")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddGarment = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddGarment) {
                AddGarmentView()
            }
            .sheet(item: $selectedGarment) { garment in
                FitDetailView(garment: garment)
            }
        }
    }
    
    private var garmentGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppSpacing.md) {
                ForEach(appSession.garments) { garment in
                    GarmentCard(garment: garment) {
                        selectedGarment = garment
                    }
                }
            }
            .padding(AppSpacing.md)
        }
    }
}

struct GarmentCard: View {
    let garment: Garment
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                // Garment Image Placeholder
                RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                    .fill(AppColors.tertiaryBackground)
                    .frame(height: 120)
                    .overlay(
                        VStack(spacing: AppSpacing.xs) {
                            Image(systemName: iconForCategory(garment.category))
                                .font(.title2)
                                .foregroundColor(AppColors.secondaryText)
                            
                            Text(garment.category.displayName)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.secondaryText)
                        }
                    )
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(garment.name)
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.text)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if let brand = garment.brand {
                        Text(brand)
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.secondaryText)
                    }
                    
                    HStack {
                        FitRatingBadge(rating: garment.intendedFit.capitalized)
                        
                        Spacer()
                        
                        Text(garment.category.displayName)
                            .font(AppTypography.caption2)
                            .foregroundColor(AppColors.tertiaryText)
                    }
                }
            }
            .padding(AppSpacing.sm)
            .background(AppColors.secondaryBackground)
            .cornerRadius(AppCornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func iconForCategory(_ category: GarmentCategory) -> String {
        switch category {
        case .tshirt:
            return "tshirt"
        case .shirt:
            return "tshirt"
        case .hoodie:
            return "hoodie"
        case .jeans:
            return "figure.walk"
        case .trousers:
            return "figure.walk"
        case .skirt:
            return "figure.walk"
        case .dress:
            return "figure.walk"
        case .jacket:
            return "jacket"
        }
    }
}

#Preview {
    ClosetView()
        .environmentObject(AppSession())
}
