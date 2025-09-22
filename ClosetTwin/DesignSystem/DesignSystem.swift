//
//  DesignSystem.swift
//  ClosetTwin
//
//  Created by David Gogoana on 22.09.2025.
//

import SwiftUI

// MARK: - Colors
struct AppColors {
    static let primary = Color(red: 0.2, green: 0.4, blue: 0.8) // Blue
    static let secondary = Color(red: 0.9, green: 0.6, blue: 0.2) // Orange
    static let accent = Color(red: 0.7, green: 0.3, blue: 0.9) // Purple
    
    static let background = Color(UIColor.systemBackground)
    static let secondaryBackground = Color(UIColor.secondarySystemBackground)
    static let tertiaryBackground = Color(UIColor.tertiarySystemBackground)
    
    static let text = Color(UIColor.label)
    static let secondaryText = Color(UIColor.secondaryLabel)
    static let tertiaryText = Color(UIColor.tertiaryLabel)
    
    // Fit rating colors
    static let tooTight = Color.red
    static let close = Color.orange
    static let comfy = Color.green
    static let oversized = Color.blue
    static let relaxed = Color.purple
}

// MARK: - Typography
struct AppTypography {
    static let largeTitle = Font.largeTitle.weight(.bold)
    static let title1 = Font.title.weight(.semibold)
    static let title2 = Font.title2.weight(.semibold)
    static let title3 = Font.title3.weight(.medium)
    static let headline = Font.headline.weight(.semibold)
    static let body = Font.body
    static let callout = Font.callout
    static let subheadline = Font.subheadline
    static let footnote = Font.footnote
    static let caption = Font.caption
    static let caption2 = Font.caption2
}

// MARK: - Spacing
struct AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius
struct AppCornerRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
}

// MARK: - Common Components
struct CardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(AppSpacing.md)
            .background(AppColors.secondaryBackground)
            .cornerRadius(AppCornerRadius.md)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isDisabled: Bool = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(isDisabled ? AppColors.tertiaryText : AppColors.primary)
                .cornerRadius(AppCornerRadius.sm)
        }
        .disabled(isDisabled)
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.headline)
                .foregroundColor(AppColors.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(AppColors.primary.opacity(0.1))
                .cornerRadius(AppCornerRadius.sm)
        }
    }
}

struct FitRatingBadge: View {
    let rating: String
    
    private var color: Color {
        switch rating {
        case "Too Tight":
            return AppColors.tooTight
        case "Close":
            return AppColors.close
        case "Comfy":
            return AppColors.comfy
        case "Oversized", "Relaxed":
            return AppColors.oversized
        default:
            return AppColors.secondaryText
        }
    }
    
    var body: some View {
        Text(rating)
            .font(AppTypography.caption)
            .foregroundColor(.white)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(color)
            .cornerRadius(AppCornerRadius.sm)
    }
}

struct MeasurementInputField: View {
    let title: String
    @Binding var value: Double
    let unit: String
    let range: ClosedRange<Double>
    let helpText: String?
    
    @State private var textValue: String = ""
    @State private var showingHelp: Bool = false
    
    init(title: String, value: Binding<Double>, unit: String, range: ClosedRange<Double>, helpText: String? = nil) {
        self.title = title
        self._value = value
        self.unit = unit
        self.range = range
        self.helpText = helpText
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                Text(title)
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.text)
                
                if let helpText = helpText {
                    Button(action: { showingHelp.toggle() }) {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(AppColors.secondaryText)
                            .font(.caption)
                    }
                }
                
                Spacer()
            }
            
            HStack {
                TextField("0", text: $textValue)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: textValue) { _, newValue in
                        if let doubleValue = Double(newValue), range.contains(doubleValue) {
                            value = doubleValue
                        }
                    }
                    .onAppear {
                        textValue = String(format: "%.1f", value)
                    }
                
                Text(unit)
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.secondaryText)
            }
            
            if showingHelp, let helpText = helpText {
                Text(helpText)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.secondaryText)
                    .padding(.top, AppSpacing.xs)
            }
        }
    }
}

struct LoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            ProgressView()
                .scaleEffect(1.2)
            Text(message)
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background.opacity(0.8))
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(icon: String, title: String, message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(AppColors.secondaryText)
            
            VStack(spacing: AppSpacing.sm) {
                Text(title)
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.text)
                
                Text(message)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                PrimaryButton(title: actionTitle, action: action)
                    .padding(.horizontal, AppSpacing.xl)
            }
        }
        .padding(AppSpacing.xl)
    }
}
