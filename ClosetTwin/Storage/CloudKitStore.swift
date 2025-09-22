//
//  CloudKitStore.swift
//  ClosetTwin
//
//  Created by David Gogoana on 22.09.2025.
//

import Foundation
import CloudKit
import Combine

// MARK: - CloudKit Errors
enum CloudKitError: Error, LocalizedError {
    case notAuthenticated
    case recordNotFound
    case networkError
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated with iCloud"
        case .recordNotFound:
            return "Record not found"
        case .networkError:
            return "Network error occurred"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}

// MARK: - CloudKitStore
@MainActor
class CloudKitStore: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let publicDatabase: CKDatabase
    
    init() {
        self.container = CKContainer.default()
        self.privateDatabase = container.privateCloudDatabase
        self.publicDatabase = container.publicCloudDatabase
    }
    
    // MARK: - Authentication
    func checkAccountStatus() async throws -> CKAccountStatus {
        return try await container.accountStatus()
    }
    
    // MARK: - User Profile Operations
    func saveUserProfile(_ profile: UserProfile) async throws {
        let record = try profileToRecord(profile)
        try await privateDatabase.save(record)
    }
    
    func fetchUserProfile(appleUserId: String) async throws -> UserProfile? {
        let predicate = NSPredicate(format: "appleUserId == %@", appleUserId)
        let query = CKQuery(recordType: "UserProfile", predicate: predicate)
        
        let results = try await privateDatabase.records(matching: query)
        
        guard let record = results.matchResults.first?.1 else {
            return nil
        }
        
        switch record {
        case .success(let record):
            return try recordToUserProfile(record)
        case .failure(let error):
            throw CloudKitError.unknown(error)
        }
    }
    
    // MARK: - Measurement Set Operations
    func saveMeasurementSet(_ measurementSet: MeasurementSet, userProfileId: UUID) async throws {
        let record = try measurementSetToRecord(measurementSet, userProfileId: userProfileId)
        try await privateDatabase.save(record)
    }
    
    func fetchMeasurementSets(for userProfileId: UUID) async throws -> [MeasurementSet] {
        let predicate = NSPredicate(format: "userProfileId == %@", CKRecord.Reference(recordID: CKRecord.ID(recordName: userProfileId.uuidString), action: .deleteSelf))
        let query = CKQuery(recordType: "MeasurementSet", predicate: predicate)
        
        let results = try await privateDatabase.records(matching: query)
        
        var measurementSets: [MeasurementSet] = []
        
        for (_, record) in results.matchResults {
            switch record {
            case .success(let record):
                if let measurementSet = try? recordToMeasurementSet(record) {
                    measurementSets.append(measurementSet)
                }
            case .failure(let error):
                print("Failed to fetch measurement set: \(error)")
            }
        }
        
        return measurementSets.sorted { $0.createdAt < $1.createdAt }
    }
    
    func deleteMeasurementSet(id: UUID) async throws {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        try await privateDatabase.deleteRecord(withID: recordID)
    }
    
    // MARK: - Garment Operations
    func saveGarment(_ garment: Garment, userProfileId: UUID) async throws {
        let record = try garmentToRecord(garment, userProfileId: userProfileId)
        try await privateDatabase.save(record)
    }
    
    func fetchGarments(for userProfileId: UUID) async throws -> [Garment] {
        let predicate = NSPredicate(format: "userProfileId == %@", CKRecord.Reference(recordID: CKRecord.ID(recordName: userProfileId.uuidString), action: .deleteSelf))
        let query = CKQuery(recordType: "Garment", predicate: predicate)
        
        let results = try await privateDatabase.records(matching: query)
        
        var garments: [Garment] = []
        
        for (_, record) in results.matchResults {
            switch record {
            case .success(let record):
                if let garment = try? recordToGarment(record) {
                    garments.append(garment)
                }
            case .failure(let error):
                print("Failed to fetch garment: \(error)")
            }
        }
        
        return garments.sorted { $0.createdAt > $1.createdAt }
    }
    
    func deleteGarment(id: UUID) async throws {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        try await privateDatabase.deleteRecord(withID: recordID)
    }
    
    // MARK: - Shared Avatar Operations
    func saveSharedAvatar(token: String, profile: UserProfile, measurementSet: MeasurementSet) async throws {
        let record = CKRecord(recordType: "SharedAvatar")
        record["token"] = token
        record["profileData"] = try JSONEncoder().encode(SharedAvatarData(
            displayName: profile.displayName,
            gender: profile.gender,
            preferences: profile.preferences
        ))
        record["measurementData"] = try JSONEncoder().encode(measurementSet)
        record["createdAt"] = Date()
        
        try await publicDatabase.save(record)
    }
    
    func fetchSharedAvatar(token: String) async throws -> (profile: SharedAvatarData, measurements: MeasurementSet)? {
        let predicate = NSPredicate(format: "token == %@", token)
        let query = CKQuery(recordType: "SharedAvatar", predicate: predicate)
        
        let results = try await publicDatabase.records(matching: query)
        
        guard let record = results.matchResults.first?.1 else {
            return nil
        }
        
        switch record {
        case .success(let record):
            guard let profileData = record["profileData"] as? Data,
                  let measurementData = record["measurementData"] as? Data else {
                throw CloudKitError.recordNotFound
            }
            
            let profile = try JSONDecoder().decode(SharedAvatarData.self, from: profileData)
            let measurements = try JSONDecoder().decode(MeasurementSet.self, from: measurementData)
            
            return (profile: profile, measurements: measurements)
        case .failure(let error):
            throw CloudKitError.unknown(error)
        }
    }
    
    func deleteSharedAvatar(token: String) async throws {
        let predicate = NSPredicate(format: "token == %@", token)
        let query = CKQuery(recordType: "SharedAvatar", predicate: predicate)
        
        let results = try await publicDatabase.records(matching: query)
        
        for (recordID, _) in results.matchResults {
            try await publicDatabase.deleteRecord(withID: recordID)
        }
    }
}

// MARK: - Shared Avatar Data
struct SharedAvatarData: Codable {
    let displayName: String?
    let gender: Gender
    let preferences: FitPreferences
}

// MARK: - Record Conversion Extensions
private extension CloudKitStore {
    
    func profileToRecord(_ profile: UserProfile) throws -> CKRecord {
        let record = CKRecord(recordType: "UserProfile", recordID: CKRecord.ID(recordName: profile.id.uuidString))
        record["appleUserId"] = profile.appleUserId
        record["displayName"] = profile.displayName
        record["gender"] = profile.gender.rawValue
        record["activeMeasurementId"] = profile.activeMeasurementId?.uuidString
        record["preferences"] = try JSONEncoder().encode(profile.preferences)
        record["sharedPublicToken"] = profile.sharedPublicToken
        record["createdAt"] = profile.createdAt
        record["updatedAt"] = profile.updatedAt
        
        return record
    }
    
    func recordToUserProfile(_ record: CKRecord) throws -> UserProfile {
        guard let appleUserId = record["appleUserId"] as? String,
              let genderString = record["gender"] as? String,
              let gender = Gender(rawValue: genderString),
              let preferencesData = record["preferences"] as? Data,
              let preferences = try? JSONDecoder().decode(FitPreferences.self, from: preferencesData),
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date else {
            throw CloudKitError.recordNotFound
        }
        
        let id = record.recordID.recordName
        let displayName = record["displayName"] as? String
        let activeMeasurementId = (record["activeMeasurementId"] as? String).flatMap(UUID.init)
        let sharedPublicToken = record["sharedPublicToken"] as? String
        
        return UserProfile(
            id: UUID(uuidString: id) ?? UUID(),
            appleUserId: appleUserId,
            displayName: displayName,
            gender: gender,
            activeMeasurementId: activeMeasurementId,
            preferences: preferences,
            sharedPublicToken: sharedPublicToken,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    func measurementSetToRecord(_ measurementSet: MeasurementSet, userProfileId: UUID) throws -> CKRecord {
        let record = CKRecord(recordType: "MeasurementSet", recordID: CKRecord.ID(recordName: measurementSet.id.uuidString))
        record["userProfileId"] = CKRecord.Reference(recordID: CKRecord.ID(recordName: userProfileId.uuidString), action: .deleteSelf)
        record["data"] = try JSONEncoder().encode(measurementSet)
        
        return record
    }
    
    func recordToMeasurementSet(_ record: CKRecord) throws -> MeasurementSet {
        guard let data = record["data"] as? Data else {
            throw CloudKitError.recordNotFound
        }
        
        return try JSONDecoder().decode(MeasurementSet.self, from: data)
    }
    
    func garmentToRecord(_ garment: Garment, userProfileId: UUID) throws -> CKRecord {
        let record = CKRecord(recordType: "Garment", recordID: CKRecord.ID(recordName: garment.id.uuidString))
        record["userProfileId"] = CKRecord.Reference(recordID: CKRecord.ID(recordName: userProfileId.uuidString), action: .deleteSelf)
        record["data"] = try JSONEncoder().encode(garment)
        
        return record
    }
    
    func recordToGarment(_ record: CKRecord) throws -> Garment {
        guard let data = record["data"] as? Data else {
            throw CloudKitError.recordNotFound
        }
        
        return try JSONDecoder().decode(Garment.self, from: data)
    }
}
