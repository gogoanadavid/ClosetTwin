//
//  ClosetTwinApp.swift
//  ClosetTwin
//
//  Created by David Gogoana on 22.09.2025.
//

import SwiftUI

@main
struct ClosetTwinApp: App {
    @StateObject private var appSession = AppSession()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if appSession.isAuthenticated {
                    MainTabView()
                        .environmentObject(appSession)
                } else {
                    AuthenticationView()
                        .environmentObject(appSession)
                }
            }
            .onAppear {
                print("ClosetTwinApp appeared - isAuthenticated: \(appSession.isAuthenticated)")
                // Check authentication status on app launch
                appSession.authManager.checkAuthenticationStatus()
            }
        }
    }
}
