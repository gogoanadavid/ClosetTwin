//
//  FitEngine.swift
//  ClosetTwin
//
//  Created by David Gogoana on 22.09.2025.
//

import Foundation

// MARK: - FitMode
enum FitMode: String, Codable {
    case basic = "basic"
    case advanced = "advanced"
}

// MARK: - EaseTables
struct EaseTables {
    // cm, conservative defaults
    static let top: [String: [String: Double]] = [
        "slim": ["chest": 4, "waist": 3, "hip": 3, "shoulder": 1],
        "regular": ["chest": 6, "waist": 5, "hip": 5, "shoulder": 1.5],
        "oversized": ["chest": 12, "waist": 10, "hip": 10, "shoulder": 2]
    ]
    
    static let bottom: [String: [String: Double]] = [
        "slim": ["waist": 2, "hip": 3, "thigh": 2, "hem": 0],
        "regular": ["waist": 3, "hip": 4, "thigh": 3, "hem": 0],
        "oversized": ["waist": 6, "hip": 8, "thigh": 6, "hem": 0]
    ]
}

// MARK: - FitEngine
struct FitEngine {
    
    // MARK: - Main Evaluation Function
    static func evaluate(garment: Garment, body: MeasurementSet, prefs: FitPreferences, mode: FitMode) -> FitResult {
        switch mode {
        case .basic:
            return basicFit(garment: garment, body: body, prefs: prefs)
        case .advanced:
            return advancedFit(garment: garment, body: body, prefs: prefs)
        }
    }
    
    // MARK: - Basic Fit Mode
    private static func basicFit(garment: Garment, body: MeasurementSet, prefs: FitPreferences) -> FitResult {
        var zones: [FitZoneResult] = []
        var zoneRatings: [String] = []
        
        // Determine which zones to evaluate based on garment category
        let zonesToEvaluate = getZonesForCategory(garment.category)
        
        for zone in zonesToEvaluate {
            let bodyCirc = bodyCircumference(for: zone, body: body)
            let garmentCirc = garmentCircumference(for: zone, garment: garment)
            let requiredEase = getRequiredEase(for: zone, category: garment.category, intendedFit: garment.intendedFit)
            
            let delta = garmentCirc - (bodyCirc + requiredEase)
            let rating = mapDeltaToRating(delta: delta)
            
            let zoneResult = FitZoneResult(zone: zone, deltaCm: delta, rating: rating)
            zones.append(zoneResult)
            zoneRatings.append(rating)
        }
        
        let overall = determineOverallRating(zoneRatings: zoneRatings)
        let sizeMatchPercent = calculateSizeMatchPercent(zoneRatings: zoneRatings)
        let summary = generateSummary(mode: "Basic", zones: zones, overall: overall)
        
        return FitResult(
            summary: summary,
            mode: "Basic",
            zones: zones,
            overall: overall,
            sizeMatchPercent: sizeMatchPercent
        )
    }
    
    // MARK: - Advanced Fit Mode
    private static func advancedFit(garment: Garment, body: MeasurementSet, prefs: FitPreferences) -> FitResult {
        var zones: [FitZoneResult] = []
        var zoneRatings: [String] = []
        
        let zonesToEvaluate = getZonesForCategory(garment.category)
        
        for zone in zonesToEvaluate {
            let bodyCirc = bodyCircumference(for: zone, body: body)
            let garmentCirc = garmentCircumference(for: zone, garment: garment)
            let requiredEase = getRequiredEase(for: zone, category: garment.category, intendedFit: garment.intendedFit)
            
            // Calculate strain with fabric stretch consideration
            let stretchFactor = calculateStretchFactor(fabric: garment.fabric)
            let effectiveGarmentCapacity = garmentCirc * stretchFactor
            let strain = max(0, (bodyCirc + requiredEase - effectiveGarmentCapacity) / (garmentCirc * stretchFactor))
            let normalizedStrain = min(1.0, strain / 1.5) // Normalize to [0, 1]
            
            // Apply asymmetry bias for common stress areas
            let adjustedStrain = applyAsymmetryBias(strain: normalizedStrain, zone: zone)
            
            // Apply user preferences
            let toleranceAdjustedStrain = adjustForUserPreferences(
                strain: adjustedStrain,
                zone: zone,
                preferences: prefs
            )
            
            let rating = mapStrainToRating(strain: toleranceAdjustedStrain)
            
            let zoneResult = FitZoneResult(
                zone: zone,
                deltaCm: garmentCirc - (bodyCirc + requiredEase),
                rating: rating,
                strain: toleranceAdjustedStrain
            )
            zones.append(zoneResult)
            zoneRatings.append(rating)
        }
        
        let overall = determineOverallRating(zoneRatings: zoneRatings)
        let sizeMatchPercent = calculateSizeMatchPercent(zoneRatings: zoneRatings)
        let summary = generateAdvancedSummary(mode: "Advanced", zones: zones, overall: overall)
        
        return FitResult(
            summary: summary,
            mode: "Advanced",
            zones: zones,
            overall: overall,
            sizeMatchPercent: sizeMatchPercent
        )
    }
    
    // MARK: - Helper Functions
    
    private static func getZonesForCategory(_ category: GarmentCategory) -> [String] {
        if category.isTop {
            return ["chest", "waist", "hip", "shoulder"]
        } else {
            return ["waist", "hip", "thigh", "hem"]
        }
    }
    
    private static func bodyCircumference(for zone: String, body: MeasurementSet) -> Double {
        switch zone {
        case "chest":
            return body.chestBustCm
        case "waist":
            return body.waistCm
        case "hip":
            return body.highHipCm
        case "shoulder":
            return body.shoulderWidthCm
        case "thigh":
            return body.thighCm
        case "hem":
            return body.calfCm
        default:
            return 0
        }
    }
    
    private static func garmentCircumference(for zone: String, garment: Garment) -> Double {
        switch zone {
        case "chest":
            if let circ = garment.measurements.chestCircumferenceCm {
                return circ
            } else if let flat = garment.measurements.chestFlatCm {
                return flat * 2 // Convert flat to circumference
            }
            return 0
        case "waist":
            if let circ = garment.measurements.waistCircumferenceCm {
                return circ
            } else if let flat = garment.measurements.waistFlatCm {
                return flat * 2
            }
            return 0
        case "hip":
            if let circ = garment.measurements.hipCircumferenceCm {
                return circ
            } else if let flat = garment.measurements.hipFlatCm {
                return flat * 2
            }
            return 0
        case "shoulder":
            return garment.measurements.shoulderCm ?? 0
        case "thigh":
            return (garment.measurements.thighFlatCm ?? 0) * 2
        case "hem":
            return (garment.measurements.hemFlatCm ?? 0) * 2
        default:
            return 0
        }
    }
    
    private static func getRequiredEase(for zone: String, category: GarmentCategory, intendedFit: String) -> Double {
        let table = category.isTop ? EaseTables.top : EaseTables.bottom
        return table[intendedFit]?[zone] ?? 0
    }
    
    private static func mapDeltaToRating(delta: Double) -> String {
        if delta < -2 {
            return "Too Tight"
        } else if delta >= -2 && delta <= 1 {
            return "Close"
        } else if delta > 1 && delta <= 5 {
            return "Comfy"
        } else {
            return "Oversized"
        }
    }
    
    private static func mapStrainToRating(strain: Double) -> String {
        if strain >= 0.8 {
            return "Too Tight"
        } else if strain >= 0.5 {
            return "Close"
        } else if strain >= 0.2 {
            return "Comfy"
        } else {
            return "Relaxed"
        }
    }
    
    private static func calculateStretchFactor(fabric: Fabric?) -> Double {
        guard let fabric = fabric else { return 1.0 }
        let k: Double = 0.4 // Default stretch factor constant
        return 1.0 + (fabric.stretchPercent / 100.0) * k
    }
    
    private static func applyAsymmetryBias(strain: Double, zone: String) -> Double {
        // Apply 10-20% strain increase for common stress areas
        let stressZones = ["hip", "waist", "chest"]
        if stressZones.contains(zone) {
            return strain * 1.15 // 15% increase
        }
        return strain
    }
    
    private static func adjustForUserPreferences(strain: Double, zone: String, preferences: FitPreferences) -> Double {
        let tolerance = preferences.tightnessToleranceCm / 10.0 // Convert cm to strain units
        return max(0, strain - tolerance)
    }
    
    private static func determineOverallRating(zoneRatings: [String]) -> String {
        let tightCount = zoneRatings.filter { $0 == "Too Tight" }.count
        let closeCount = zoneRatings.filter { $0 == "Close" }.count
        let comfyCount = zoneRatings.filter { $0 == "Comfy" }.count
        let oversizedCount = zoneRatings.filter { $0 == "Oversized" || $0 == "Relaxed" }.count
        
        if tightCount > 0 {
            return "Tight"
        } else if closeCount > comfyCount + oversizedCount {
            return "Close"
        } else if comfyCount >= closeCount + oversizedCount {
            return "Comfy"
        } else {
            return "Loose"
        }
    }
    
    private static func calculateSizeMatchPercent(zoneRatings: [String]) -> Int {
        let totalZones = zoneRatings.count
        guard totalZones > 0 else { return 0 }
        
        let goodMatches = zoneRatings.filter { $0 == "Comfy" || $0 == "Close" }.count
        return Int((Double(goodMatches) / Double(totalZones)) * 100)
    }
    
    private static func generateSummary(mode: String, zones: [FitZoneResult], overall: String) -> String {
        let zoneCount = zones.count
        let tightZones = zones.filter { $0.rating == "Too Tight" }.count
        let comfyZones = zones.filter { $0.rating == "Comfy" }.count
        
        if tightZones > 0 {
            return "\(mode) analysis shows tightness in \(tightZones) of \(zoneCount) zones. Overall fit is \(overall.lowercased())."
        } else if comfyZones == zoneCount {
            return "\(mode) analysis shows comfortable fit across all \(zoneCount) zones. Overall fit is \(overall.lowercased())."
        } else {
            return "\(mode) analysis shows mixed fit results across \(zoneCount) zones. Overall fit is \(overall.lowercased())."
        }
    }
    
    private static func generateAdvancedSummary(mode: String, zones: [FitZoneResult], overall: String) -> String {
        let highStrainZones = zones.filter { ($0.strain ?? 0) > 0.7 }.count
        let lowStrainZones = zones.filter { ($0.strain ?? 0) < 0.3 }.count
        
        if highStrainZones > 0 {
            return "\(mode) analysis with strain modeling shows high stress in \(highStrainZones) zones. Consider sizing up or choosing stretchier fabric."
        } else if lowStrainZones == zones.count {
            return "\(mode) analysis shows low strain across all zones. Fabric will drape comfortably."
        } else {
            return "\(mode) analysis with strain modeling shows moderate fit with some stress points. Overall fit is \(overall.lowercased())."
        }
    }
}
