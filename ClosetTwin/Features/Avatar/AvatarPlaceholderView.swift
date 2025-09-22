//
//  AvatarPlaceholderView.swift
//  ClosetTwin
//
//  Created by David Gogoana on 22.09.2025.
//

import SwiftUI

struct AvatarPlaceholderView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: AppCornerRadius.lg)
            .stroke(style: StrokeStyle(lineWidth: 2, dash: [6]))
            .overlay(
                VStack(spacing: AppSpacing.sm) {
                    Image(systemName: "person.crop.square")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundColor(AppColors.secondaryText)
                    
                    Text("Avatar placeholder")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.text)
                    
                    Text("2D/3D rendering intentionally omitted in MVP")
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(AppSpacing.lg)
            )
            .frame(maxWidth: .infinity, minHeight: 260)
            .padding(AppSpacing.md)
            .background(AppColors.secondaryBackground)
            .cornerRadius(AppCornerRadius.lg)
    }
}

#Preview {
    AvatarPlaceholderView()
        .padding()
}
