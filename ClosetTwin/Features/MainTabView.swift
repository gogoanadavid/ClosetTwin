//
//  MainTabView.swift
//  ClosetTwin
//
//  Created by David Gogoana on 22.09.2025.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appSession: AppSession
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
            
            ClosetView()
                .tabItem {
                    Image(systemName: "tshirt")
                    Text("Closet")
                }
            
            QRScanView()
                .tabItem {
                    Image(systemName: "qrcode.viewfinder")
                    Text("Scan")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
        }
        .accentColor(AppColors.primary)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppSession())
}
