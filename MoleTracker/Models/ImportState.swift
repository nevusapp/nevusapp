//
//  ImportState.swift
//  MoleTracker
//
//  Created on 28.02.2026.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ImportState: ObservableObject {
    @Published var importURL: URL?
    @Published var showingImportConfirmation = false
    
    // Store the original file URL for deletion after import
    var originalFileURL: URL?
    
    // Track if import was successful
    var importSucceeded = false
    
    func setImportURL(_ url: URL) {
        print("🔗 ImportState: Setting URL to \(url.lastPathComponent)")
        self.importURL = url
        print("   ImportState: URL is now \(self.importURL?.lastPathComponent ?? "nil")")
        self.showingImportConfirmation = true
        print("   ImportState: Sheet flag is now \(self.showingImportConfirmation)")
    }
    
    func reset() {
        print("🔄 ImportState: Resetting")
        importURL = nil
        originalFileURL = nil
        importSucceeded = false
        showingImportConfirmation = false
    }
}
