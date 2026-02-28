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
    @State private var importURL: URL?
    @State private var showingImportConfirmation = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // Request notification permission on first launch
                    let _ = await notificationService.requestNotificationPermission()
                }
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
                .sheet(isPresented: $showingImportConfirmation) {
                    if let url = importURL {
                        ImportConfirmationView(fileURL: url)
                    }
                }
        }
        .modelContainer(for: [Mole.self, MoleImage.self, BodyRegionOverview.self, MoleLocationMarker.self])
    }
    
    private func handleIncomingURL(_ url: URL) {
        // Check if it's a sync package file
        if url.pathExtension == "moletracker" {
            importURL = url
            showingImportConfirmation = true
        }
    }
}