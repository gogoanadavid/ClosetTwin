//
//  FitEngineTests.swift
//  ClosetTwinTests
//
//  Created by David Gogoana on 22.09.2025.
//

import XCTest
@testable import ClosetTwin

final class FitEngineTests: XCTestCase {
    
    func testBasicFitEvaluation() throws {
        // Given
        let measurementSet = MeasurementSet(
            name: "Test Measurements",
            gender: .unspecified,
            heightCm: 170,
            chestBustCm: 90,
            underbustCm: 80,
            waistCm: 75,
            highHipCm: 95,
            lowHipSeatCm: 100,
            shoulderWidthCm: 45,
            armLengthCm: 60,
            bicepCm: 30,
            inseamCm: 80,
            thighCm: 55,
            calfCm: 35
        )
        
        let garment = Garment(
            name: "Test T-Shirt",
            category: .tshirt,
            intendedFit: "regular",
            measurements: GarmentMeasurements(
                chestFlatCm: 50, // 100cm circumference
                waistFlatCm: 45,  // 90cm circumference
                lengthCm: 70
            )
        )
        
        let preferences = FitPreferences(
            tightnessToleranceCm: 2.0,
            preferredFit: "regular"
        )
        
        // When
        let result = FitEngine.evaluate(
            garment: garment,
            body: measurementSet,
            prefs: preferences,
            mode: .basic
        )
        
        // Then
        XCTAssertEqual(result.mode, "Basic")
        XCTAssertFalse(result.zones.isEmpty)
        XCTAssertNotNil(result.summary)
        XCTAssertNotNil(result.overall)
    }
    
    func testAdvancedFitEvaluation() throws {
        // Given
        let measurementSet = MeasurementSet(
            name: "Test Measurements",
            gender: .unspecified,
            heightCm: 170,
            chestBustCm: 90,
            underbustCm: 80,
            waistCm: 75,
            highHipCm: 95,
            lowHipSeatCm: 100,
            shoulderWidthCm: 45,
            armLengthCm: 60,
            bicepCm: 30,
            inseamCm: 80,
            thighCm: 55,
            calfCm: 35
        )
        
        let garment = Garment(
            name: "Test T-Shirt",
            category: .tshirt,
            intendedFit: "regular",
            measurements: GarmentMeasurements(
                chestFlatCm: 50,
                waistFlatCm: 45,
                lengthCm: 70
            ),
            fabric: Fabric(stretchPercent: 5.0, weightGsm: 180)
        )
        
        let preferences = FitPreferences(
            tightnessToleranceCm: 2.0,
            preferredFit: "regular"
        )
        
        // When
        let result = FitEngine.evaluate(
            garment: garment,
            body: measurementSet,
            prefs: preferences,
            mode: .advanced
        )
        
        // Then
        XCTAssertEqual(result.mode, "Advanced")
        XCTAssertFalse(result.zones.isEmpty)
        XCTAssertNotNil(result.summary)
        XCTAssertNotNil(result.overall)
        
        // Check that strain values are present in advanced mode
        let hasStrainValues = result.zones.contains { $0.strain != nil }
        XCTAssertTrue(hasStrainValues, "Advanced mode should include strain values")
    }
    
    func testTightFitDetection() throws {
        // Given
        let measurementSet = MeasurementSet(
            name: "Test Measurements",
            gender: .unspecified,
            heightCm: 170,
            chestBustCm: 90,
            underbustCm: 80,
            waistCm: 75,
            highHipCm: 95,
            lowHipSeatCm: 100,
            shoulderWidthCm: 45,
            armLengthCm: 60,
            bicepCm: 30,
            inseamCm: 80,
            thighCm: 55,
            calfCm: 35
        )
        
        // Garment with very tight measurements
        let garment = Garment(
            name: "Tight T-Shirt",
            category: .tshirt,
            intendedFit: "slim",
            measurements: GarmentMeasurements(
                chestFlatCm: 40, // 80cm circumference (90cm body + 4cm ease = 94cm needed)
                waistFlatCm: 35,  // 70cm circumference (75cm body + 3cm ease = 78cm needed)
                lengthCm: 70
            )
        )
        
        let preferences = FitPreferences(
            tightnessToleranceCm: 1.0,
            preferredFit: "regular"
        )
        
        // When
        let result = FitEngine.evaluate(
            garment: garment,
            body: measurementSet,
            prefs: preferences,
            mode: .basic
        )
        
        // Then
        XCTAssertEqual(result.overall, "Tight")
        
        // Check that tight zones are detected
        let tightZones = result.zones.filter { $0.rating == "Too Tight" }
        XCTAssertFalse(tightZones.isEmpty, "Should detect tight zones")
    }
    
    func testOversizedFitDetection() throws {
        // Given
        let measurementSet = MeasurementSet(
            name: "Test Measurements",
            gender: .unspecified,
            heightCm: 170,
            chestBustCm: 90,
            underbustCm: 80,
            waistCm: 75,
            highHipCm: 95,
            lowHipSeatCm: 100,
            shoulderWidthCm: 45,
            armLengthCm: 60,
            bicepCm: 30,
            inseamCm: 80,
            thighCm: 55,
            calfCm: 35
        )
        
        // Garment with very loose measurements
        let garment = Garment(
            name: "Oversized Hoodie",
            category: .hoodie,
            intendedFit: "oversized",
            measurements: GarmentMeasurements(
                chestFlatCm: 70, // 140cm circumference (90cm body + 12cm ease = 102cm needed)
                waistFlatCm: 65,  // 130cm circumference (75cm body + 10cm ease = 85cm needed)
                lengthCm: 70
            )
        )
        
        let preferences = FitPreferences(
            tightnessToleranceCm: 2.0,
            preferredFit: "regular"
        )
        
        // When
        let result = FitEngine.evaluate(
            garment: garment,
            body: measurementSet,
            prefs: preferences,
            mode: .basic
        )
        
        // Then
        XCTAssertEqual(result.overall, "Loose")
        
        // Check that oversized zones are detected
        let oversizedZones = result.zones.filter { $0.rating == "Oversized" }
        XCTAssertFalse(oversizedZones.isEmpty, "Should detect oversized zones")
    }
}
