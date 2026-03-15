//
//  GuidedScanningService.swift
//  MoleTracker
//
//  Created on 11.01.2026.
//

import Foundation
import SwiftUI
import SwiftData
import Combine

/// Service to manage guided scanning workflow
@MainActor
class GuidedScanningService: ObservableObject {
    @Published var isScanning = false
    @Published var currentMoleIndex = 0
    @Published var scannedMoles: Set<UUID> = []
    @Published var skippedMoles: Set<UUID> = []
    
    private(set) var molesToScan: [Mole] = []
    private var originalTotalCount: Int = 0
    
    var totalMoles: Int {
        originalTotalCount
    }
    
    var scannedCount: Int {
        scannedMoles.count
    }
    
    var remainingCount: Int {
        totalMoles - scannedCount - skippedMoles.count
    }
    
    var progress: Double {
        guard totalMoles > 0 else { return 0 }
        return Double(scannedCount) / Double(totalMoles)
    }
    
    var currentMole: Mole? {
        guard currentMoleIndex < molesToScan.count else { return nil }
        return molesToScan[currentMoleIndex]
    }
    
    /// Start guided scanning session with given moles
    func startScanning(moles: [Mole]) {
        // Sort moles from top to bottom of body based on body region
        self.molesToScan = moles.sorted { mole1, mole2 in
            let region1 = BodyRegion.from(value: mole1.bodyRegion)
            let region2 = BodyRegion.from(value: mole2.bodyRegion)
            
            // Primary sort: by body region (top to bottom)
            if region1.sortOrder != region2.sortOrder {
                return region1.sortOrder < region2.sortOrder
            }
            
            // Secondary sort: by last modified (oldest first) within same region
            return mole1.lastModified < mole2.lastModified
        }
        self.originalTotalCount = moles.count
        self.currentMoleIndex = 0
        self.scannedMoles.removeAll()
        self.skippedMoles.removeAll()
        self.isScanning = true
    }
    
    /// Mark current mole as scanned and move to next
    func markCurrentAsScanned() {
        guard let mole = currentMole else { return }
        scannedMoles.insert(mole.id)
        moveToNext()
    }
    
    /// Skip current mole and move to next
    func skipCurrent() {
        guard let mole = currentMole else { return }
        skippedMoles.insert(mole.id)
        moveToNext()
    }
    
    /// Move to next mole in sequence
    private func moveToNext() {
        currentMoleIndex += 1
        
        // If we've reached the end, finish scanning
        if currentMoleIndex >= molesToScan.count {
            finishScanning()
        }
    }
    
    /// Go back to previous mole
    func goToPrevious() {
        if currentMoleIndex > 0 {
            currentMoleIndex -= 1
            
            // Remove from scanned/skipped if going back
            if let mole = currentMole {
                scannedMoles.remove(mole.id)
                skippedMoles.remove(mole.id)
            }
        }
    }
    
    /// Finish scanning session
    func finishScanning() {
        isScanning = false
        currentMoleIndex = 0
        molesToScan.removeAll()
        // Keep originalTotalCount for summary display
        
        // Record completion date and schedule notifications
        NotificationService.shared.recordGuidedScanCompletion()
    }
    
    /// Cancel scanning session
    func cancelScanning() {
        isScanning = false
        currentMoleIndex = 0
        scannedMoles.removeAll()
        skippedMoles.removeAll()
        molesToScan.removeAll()
        originalTotalCount = 0
    }
}