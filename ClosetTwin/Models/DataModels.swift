//
//  DataModels.swift
//  ClosetTwin
//
//  Created by David Gogoana on 22.09.2025.
//

import Foundation

// MARK: - Gender
enum Gender: String, Codable, CaseIterable {
    case female = "female"
    case male = "male"
    case nonbinary = "nonbinary"
    case unspecified = "unspecified"
}

// MARK: - MeasurementSet
struct MeasurementSet: Codable, Identifiable, Hashable {
    var id: UUID
    var createdAt: Date
    var name: String // e.g., "Everyday", "Gym bulk", etc.
    var gender: Gender
    var heightCm: Double
    var chestBustCm: Double
    var underbustCm: Double
    var waistCm: Double
    var highHipCm: Double
    var lowHipSeatCm: Double
    var shoulderWidthCm: Double
    var armLengthCm: Double
    var bicepCm: Double
    var inseamCm: Double
    var thighCm: Double
    var calfCm: Double
    
    init(id: UUID = UUID(), createdAt: Date = Date(), name: String, gender: Gender = .unspecified, heightCm: Double, chestBustCm: Double, underbustCm: Double, waistCm: Double, highHipCm: Double, lowHipSeatCm: Double, shoulderWidthCm: Double, armLengthCm: Double, bicepCm: Double, inseamCm: Double, thighCm: Double, calfCm: Double) {
        self.id = id
        self.createdAt = createdAt
        self.name = name
        self.gender = gender
        self.heightCm = heightCm
        self.underbustCm = underbustCm
        self.waistCm = waistCm
        self.highHipCm = highHipCm
        self.lowHipSeatCm = lowHipSeatCm
        self.shoulderWidthCm = shoulderWidthCm
        self.armLengthCm = armLengthCm
        self.bicepCm = bicepCm
        self.inseamCm = inseamCm
        self.thighCm = thighCm
        self.calfCm = calfCm
        self.heightCm = heightCm
        self.chestBustCm = chestBustCm
    }
}

// MARK: - Fabric
struct Fabric: Codable, Hashable {
    /// stretch in %, e.g., 0–2 = non-stretch, 3–7 = slight, 8–15 = stretch
    var stretchPercent: Double
    var weightGsm: Double?
    
    init(stretchPercent: Double, weightGsm: Double? = nil) {
        self.stretchPercent = stretchPercent
        self.weightGsm = weightGsm
    }
}

// MARK: - GarmentCategory
enum GarmentCategory: String, Codable, CaseIterable {
    case tshirt = "tshirt"
    case shirt = "shirt"
    case hoodie = "hoodie"
    case jeans = "jeans"
    case trousers = "trousers"
    case skirt = "skirt"
    case dress = "dress"
    case jacket = "jacket"
    
    var displayName: String {
        switch self {
        case .tshirt: return "T-Shirt"
        case .shirt: return "Shirt"
        case .hoodie: return "Hoodie"
        case .jeans: return "Jeans"
        case .trousers: return "Trousers"
        case .skirt: return "Skirt"
        case .dress: return "Dress"
        case .jacket: return "Jacket"
        }
    }
    
    var isTop: Bool {
        switch self {
        case .tshirt, .shirt, .hoodie, .dress, .jacket:
            return true
        case .jeans, .trousers, .skirt:
            return false
        }
    }
}

// MARK: - GarmentMeasurements
struct GarmentMeasurements: Codable, Hashable {
    // flat measurements where applicable; lengths are full
    var chestFlatCm: Double?      // for tops
    var waistFlatCm: Double?
    var hipFlatCm: Double?
    var shoulderCm: Double?
    var sleeveCm: Double?
    var lengthCm: Double?
    var thighFlatCm: Double?      // for bottoms
    var kneeFlatCm: Double?
    var hemFlatCm: Double?
    var riseFrontCm: Double?      // jeans/trousers
    var riseBackCm: Double?
    // raw circumference if provided (optional)
    var chestCircumferenceCm: Double?
    var waistCircumferenceCm: Double?
    var hipCircumferenceCm: Double?
    
    init(chestFlatCm: Double? = nil, waistFlatCm: Double? = nil, hipFlatCm: Double? = nil, shoulderCm: Double? = nil, sleeveCm: Double? = nil, lengthCm: Double? = nil, thighFlatCm: Double? = nil, kneeFlatCm: Double? = nil, hemFlatCm: Double? = nil, riseFrontCm: Double? = nil, riseBackCm: Double? = nil, chestCircumferenceCm: Double? = nil, waistCircumferenceCm: Double? = nil, hipCircumferenceCm: Double? = nil) {
        self.chestFlatCm = chestFlatCm
        self.waistFlatCm = waistFlatCm
        self.hipFlatCm = hipFlatCm
        self.shoulderCm = shoulderCm
        self.sleeveCm = sleeveCm
        self.lengthCm = lengthCm
        self.thighFlatCm = thighFlatCm
        self.kneeFlatCm = kneeFlatCm
        self.hemFlatCm = hemFlatCm
        self.riseFrontCm = riseFrontCm
        self.riseBackCm = riseBackCm
        self.chestCircumferenceCm = chestCircumferenceCm
        self.waistCircumferenceCm = waistCircumferenceCm
        self.hipCircumferenceCm = hipCircumferenceCm
    }
}

// MARK: - Garment
struct Garment: Codable, Identifiable, Hashable {
    var id: UUID
    var brand: String?
    var sku: String?
    var name: String
    var category: GarmentCategory
    var intendedFit: String // "slim", "regular", "oversized"
    var measurements: GarmentMeasurements
    var fabric: Fabric?
    var images: [URL]? // optional
    var createdAt: Date
    
    init(id: UUID = UUID(), brand: String? = nil, sku: String? = nil, name: String, category: GarmentCategory, intendedFit: String, measurements: GarmentMeasurements, fabric: Fabric? = nil, images: [URL]? = nil, createdAt: Date = Date()) {
        self.id = id
        self.brand = brand
        self.sku = sku
        self.name = name
        self.category = category
        self.intendedFit = intendedFit
        self.measurements = measurements
        self.fabric = fabric
        self.images = images
        self.createdAt = createdAt
    }
}

// MARK: - FitPreferences
struct FitPreferences: Codable, Hashable {
    var tightnessToleranceCm: Double // +/- band user likes
    var preferredFit: String         // "slim", "regular", "oversized"
    
    init(tightnessToleranceCm: Double = 2.0, preferredFit: String = "regular") {
        self.tightnessToleranceCm = tightnessToleranceCm
        self.preferredFit = preferredFit
    }
}

// MARK: - FitZoneResult
struct FitZoneResult: Codable, Hashable {
    var zone: String // "chest", "waist", "hip", "thigh", "shoulder", etc.
    var deltaCm: Double // garment - (body + easeAdj)
    var rating: String  // "Too Tight" | "Close" | "Comfy" | "Oversized"
    var strain: Double? // Advanced mode 0..1
    
    init(zone: String, deltaCm: Double, rating: String, strain: Double? = nil) {
        self.zone = zone
        self.deltaCm = deltaCm
        self.rating = rating
        self.strain = strain
    }
}

// MARK: - FitResult
struct FitResult: Codable, Hashable {
    var summary: String
    var mode: String // "Basic" or "Advanced"
    var zones: [FitZoneResult]
    var overall: String // "Tight", "Okay", "Comfy", "Loose"
    var sizeMatchPercent: Int? // optional
    
    init(summary: String, mode: String, zones: [FitZoneResult], overall: String, sizeMatchPercent: Int? = nil) {
        self.summary = summary
        self.mode = mode
        self.zones = zones
        self.overall = overall
        self.sizeMatchPercent = sizeMatchPercent
    }
}

// MARK: - UserProfile
struct UserProfile: Codable, Identifiable, Hashable {
    var id: UUID
    var appleUserId: String
    var displayName: String?
    var gender: Gender
    var activeMeasurementId: UUID?
    var preferences: FitPreferences
    var sharedPublicToken: String? // short token to fetch a read-only "public avatar"
    var createdAt: Date
    var updatedAt: Date
    
    init(id: UUID = UUID(), appleUserId: String, displayName: String? = nil, gender: Gender = .unspecified, activeMeasurementId: UUID? = nil, preferences: FitPreferences = FitPreferences(), sharedPublicToken: String? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.appleUserId = appleUserId
        self.displayName = displayName
        self.gender = gender
        self.activeMeasurementId = activeMeasurementId
        self.preferences = preferences
        self.sharedPublicToken = sharedPublicToken
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - SharedAvatar
struct SharedAvatar: Codable, Identifiable, Hashable {
    var id: UUID
    var token: String
    var profileName: String
    var measurementSet: MeasurementSet
    var createdAt: Date
    
    init(id: UUID = UUID(), token: String, profileName: String, measurementSet: MeasurementSet, createdAt: Date = Date()) {
        self.id = id
        self.token = token
        self.profileName = profileName
        self.measurementSet = measurementSet
        self.createdAt = createdAt
    }
}

// MARK: - PartnerPayload
struct PartnerPayload: Codable {
    let v: Int
    let brand: String
    let sku: String
    let name: String
    let category: String
    let intendedFit: String
    let measurements: GarmentMeasurements
    let fabric: Fabric?
    let sig: String?
    
    func toGarment() -> Garment {
        let category = GarmentCategory(rawValue: self.category) ?? .tshirt
        return Garment(
            brand: brand.isEmpty ? nil : brand,
            sku: sku.isEmpty ? nil : sku,
            name: name,
            category: category,
            intendedFit: intendedFit,
            measurements: measurements,
            fabric: fabric
        )
    }
}
