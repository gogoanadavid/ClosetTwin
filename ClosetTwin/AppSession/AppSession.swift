//
//  AppSession.swift
//  ClosetTwin
//
//  Created by David Gogoana on 22.09.2025.
//

import Foundation
import Combine

// MARK: - AppSession
@MainActor
class AppSession: ObservableObject {
    @Published var isAuthenticated = false
    @Published var userProfile: UserProfile?
    @Published var currentMeasurementSet: MeasurementSet?
    @Published var measurementSets: [MeasurementSet] = []
    @Published var garments: [Garment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    let authManager = AuthManager()
    private let cloudKitStore = CloudKitStore()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupAuthBinding()
    }
    
    // MARK: - Public Methods
    
    func signInWithApple() {
        authManager.signInWithApple()
    }
    
    func signOut() {
        authManager.signOut()
        userProfile = nil
        currentMeasurementSet = nil
        measurementSets = []
        garments = []
        isAuthenticated = false
    }
    
    func loadUserData() async {
        guard let profile = userProfile else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Load measurement sets
            let loadedMeasurementSets = try await cloudKitStore.fetchMeasurementSets(for: profile.id)
            measurementSets = loadedMeasurementSets
            
            // Set current measurement set
            if let activeId = profile.activeMeasurementId,
               let activeSet = loadedMeasurementSets.first(where: { $0.id == activeId }) {
                currentMeasurementSet = activeSet
            } else if let firstSet = loadedMeasurementSets.first {
                currentMeasurementSet = firstSet
                // Update profile with active measurement ID
                var updatedProfile = profile
                updatedProfile.activeMeasurementId = firstSet.id
                updatedProfile.updatedAt = Date()
                try await cloudKitStore.saveUserProfile(updatedProfile)
                userProfile = updatedProfile
            }
            
            // Load garments
            let loadedGarments = try await cloudKitStore.fetchGarments(for: profile.id)
            garments = loadedGarments
            
        } catch {
            errorMessage = "Failed to load user data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func saveMeasurementSet(_ measurementSet: MeasurementSet) async {
        guard let profile = userProfile else { return }
        
        do {
            try await cloudKitStore.saveMeasurementSet(measurementSet, userProfileId: profile.id)
            
            // Update local data
            if let index = measurementSets.firstIndex(where: { $0.id == measurementSet.id }) {
                measurementSets[index] = measurementSet
            } else {
                measurementSets.append(measurementSet)
                measurementSets.sort { $0.createdAt < $1.createdAt }
            }
            
            // Set as current if it's the only one or if it's the active one
            if measurementSets.count == 1 || profile.activeMeasurementId == measurementSet.id {
                currentMeasurementSet = measurementSet
                
                // Update profile if needed
                if profile.activeMeasurementId != measurementSet.id {
                    var updatedProfile = profile
                    updatedProfile.activeMeasurementId = measurementSet.id
                    updatedProfile.updatedAt = Date()
                    try await cloudKitStore.saveUserProfile(updatedProfile)
                    userProfile = updatedProfile
                }
            }
            
        } catch {
            errorMessage = "Failed to save measurement set: \(error.localizedDescription)"
        }
    }
    
    func deleteMeasurementSet(_ measurementSet: MeasurementSet) async {
        guard let profile = userProfile else { return }
        
        do {
            try await cloudKitStore.deleteMeasurementSet(id: measurementSet.id)
            
            // Update local data
            measurementSets.removeAll { $0.id == measurementSet.id }
            
            // Update current measurement set if needed
            if currentMeasurementSet?.id == measurementSet.id {
                currentMeasurementSet = measurementSets.first
                
                // Update profile with new active measurement ID
                if let newActiveId = measurementSets.first?.id {
                    var updatedProfile = profile
                    updatedProfile.activeMeasurementId = newActiveId
                    updatedProfile.updatedAt = Date()
                    try await cloudKitStore.saveUserProfile(updatedProfile)
                    userProfile = updatedProfile
                }
            }
            
        } catch {
            errorMessage = "Failed to delete measurement set: \(error.localizedDescription)"
        }
    }
    
    func setCurrentMeasurementSet(_ measurementSet: MeasurementSet) async {
        guard let profile = userProfile else { return }
        
        currentMeasurementSet = measurementSet
        
        // Update profile
        var updatedProfile = profile
        updatedProfile.activeMeasurementId = measurementSet.id
        updatedProfile.updatedAt = Date()
        
        do {
            try await cloudKitStore.saveUserProfile(updatedProfile)
            userProfile = updatedProfile
        } catch {
            errorMessage = "Failed to update active measurement set: \(error.localizedDescription)"
        }
    }
    
    func saveGarment(_ garment: Garment) async {
        guard let profile = userProfile else { return }
        
        do {
            try await cloudKitStore.saveGarment(garment, userProfileId: profile.id)
            
            // Update local data
            if let index = garments.firstIndex(where: { $0.id == garment.id }) {
                garments[index] = garment
            } else {
                garments.append(garment)
                garments.sort { $0.createdAt > $1.createdAt }
            }
            
        } catch {
            errorMessage = "Failed to save garment: \(error.localizedDescription)"
        }
    }
    
    func deleteGarment(_ garment: Garment) async {
        guard let profile = userProfile else { return }
        
        do {
            try await cloudKitStore.deleteGarment(id: garment.id)
            
            // Update local data
            garments.removeAll { $0.id == garment.id }
            
        } catch {
            errorMessage = "Failed to delete garment: \(error.localizedDescription)"
        }
    }
    
    func evaluateFit(garment: Garment, mode: FitMode) -> FitResult? {
        guard let measurementSet = currentMeasurementSet,
              let profile = userProfile else {
            return nil
        }
        
        return FitEngine.evaluate(
            garment: garment,
            body: measurementSet,
            prefs: profile.preferences,
            mode: mode
        )
    }
    
    // MARK: - Private Methods
    
    private func setupAuthBinding() {
        authManager.$isAuthenticated
            .assign(to: &$isAuthenticated)
        
        authManager.$userProfile
            .sink { [weak self] profile in
                self?.userProfile = profile
                if profile != nil {
                    Task {
                        await self?.loadUserData()
                    }
                }
            }
            .store(in: &cancellables)
        
        authManager.$errorMessage
            .assign(to: &$errorMessage)
        
        authManager.$isLoading
            .assign(to: &$isLoading)
    }
}
