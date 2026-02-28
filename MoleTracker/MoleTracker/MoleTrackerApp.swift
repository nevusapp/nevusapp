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
    @StateObject private var importState = ImportState()
    
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
                .sheet(isPresented: $importState.showingImportConfirmation, onDismiss: handleSheetDismiss) {
                    Group {
                        if let url = importState.importURL {
                            let _ = print("🎭 Creating ImportConfirmationView with URL: \(url.lastPathComponent)")
                            ImportConfirmationView(fileURL: url)
                        } else {
                            let _ = print("⚠️ ImportState.importURL is nil in sheet!")
                            Text("Error: No file to import")
                        }
                    }
                }
        }
        .modelContainer(for: [Mole.self, MoleImage.self, BodyRegionOverview.self, MoleLocationMarker.self])
    }
    
    private func handleIncomingURL(_ url: URL) {
        print("📥 Received URL: \(url)")
        
        // Check if it's a sync package file
        guard url.pathExtension == "moletracker" else {
            print("⚠️ Not a moletracker file")
            return
        }
        
        // Start accessing security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            print("❌ Failed to access security-scoped resource")
            return
        }
        
        // Copy file to app's temporary directory
        let fileManager = FileManager.default
        let tempURL = fileManager.temporaryDirectory
            .appendingPathComponent(url.lastPathComponent)
        
        do {
            // Remove existing temp file if present
            if fileManager.fileExists(atPath: tempURL.path) {
                try fileManager.removeItem(at: tempURL)
            }
            
            // Copy to temp location
            try fileManager.copyItem(at: url, to: tempURL)
            print("✅ File copied to: \(tempURL)")
            
            // Stop accessing the original file
            url.stopAccessingSecurityScopedResource()
            
            // Set state on main thread using ObservableObject
            Task { @MainActor in
                importState.setImportURL(tempURL)
            }
        } catch {
            print("❌ Error copying file: \(error.localizedDescription)")
            url.stopAccessingSecurityScopedResource()
        }
    }
    
    private func handleSheetDismiss() {
        print("📋 Sheet dismissed")
        // Clean up after sheet is fully dismissed
        if let url = importState.importURL {
            cleanupTempFile(url)
            importState.reset()
        }
    }
    
    private func cleanupTempFile(_ url: URL) {
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
                print("🗑️ Cleaned up temp file")
            }
        } catch {
            print("⚠️ Failed to cleanup temp file: \(error)")
        }
    }
}