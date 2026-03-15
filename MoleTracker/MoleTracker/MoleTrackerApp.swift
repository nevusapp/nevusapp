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
                                .environmentObject(importState)
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
            
            // Stop accessing the original file (but keep URL for later deletion)
            url.stopAccessingSecurityScopedResource()
            
            // Set state on main thread using ObservableObject
            Task { @MainActor in
                importState.originalFileURL = url
                importState.setImportURL(tempURL)
            }
        } catch {
            print("❌ Error copying file: \(error.localizedDescription)")
            url.stopAccessingSecurityScopedResource()
        }
    }
    
    private func handleSheetDismiss() {
        print("📋 Sheet dismissed")
        
        // Clean up temp file
        if let tempURL = importState.importURL {
            cleanupTempFile(tempURL)
        }
        
        // Delete original file if import was successful
        if importState.importSucceeded, let originalURL = importState.originalFileURL {
            deleteOriginalFile(originalURL)
        }
        
        // Reset state
        importState.reset()
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
    
    private func deleteOriginalFile(_ url: URL) {
        // Need to access security-scoped resource again for deletion
        guard url.startAccessingSecurityScopedResource() else {
            print("⚠️ Could not access original file for deletion")
            return
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
                print("✅ Deleted original sync file from Files app: \(url.lastPathComponent)")
            } else {
                print("ℹ️ Original file already removed: \(url.lastPathComponent)")
            }
        } catch {
            print("⚠️ Failed to delete original file: \(error.localizedDescription)")
            print("   User can manually delete: \(url.lastPathComponent)")
        }
    }
}