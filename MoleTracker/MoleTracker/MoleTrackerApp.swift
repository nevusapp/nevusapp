//
//  MoleTrackerApp.swift
//  MoleTracker
//
//  Created on 06.01.2026.
//

import SwiftUI
import SwiftData

@main
struct MoleTrackerApp: App {
    @StateObject private var notificationService = NotificationService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // Request notification permission on first launch
                    let _ = await notificationService.requestNotificationPermission()
                }
        }
        .modelContainer(for: [Mole.self, MoleImage.self, BodyRegionOverview.self, MoleLocationMarker.self])
    }
}