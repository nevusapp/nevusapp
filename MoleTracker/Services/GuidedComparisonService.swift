//
//  GuidedComparisonService.swift
//  MoleTracker
//
//  Created on 11.01.2026.
//

import Foundation
import SwiftUI
import SwiftData
import Combine

/// Service to manage guided comparison workflow
@MainActor
class GuidedComparisonService: ObservableObject {
    @Published var isComparing = false
    @Published var currentMoleIndex = 0
    @Published var comparedMoles: Set<UUID> = []
    @Published var skippedMoles: Set<UUID> = []
    
    private(set) var molesToCompare: [Mole] = []
    private var originalTotalCount: Int = 0
    
    var totalMoles: Int {
        originalTotalCount
    }
    
    var comparedCount: Int {
        comparedMoles.count
    }
    
    var remainingCount: Int {
        totalMoles - comparedCount - skippedMoles.count
    }
    
    var progress: Double {
        guard totalMoles > 0 else { return 0 }
        return Double(comparedCount) / Double(totalMoles)
    }
    
    var currentMole: Mole? {
        guard currentMoleIndex < molesToCompare.count else { return nil }
        return molesToCompare[currentMoleIndex]
    }
    
    /// Start guided comparison session with given moles
    /// Only includes moles that have at least 2 images (reference + latest)
    func startComparison(moles: [Mole]) {
        // Filter moles that have at least 2 images for comparison
        let comparableMoles = moles.filter { $0.imageCount >= 2 }
        
        // Sort by last modified (oldest first)
        self.molesToCompare = comparableMoles.sorted { $0.lastModified < $1.lastModified }
        self.originalTotalCount = comparableMoles.count
        self.currentMoleIndex = 0
        self.comparedMoles.removeAll()
        self.skippedMoles.removeAll()
        self.isComparing = true
    }
    
    /// Mark current mole as compared and move to next
    func markCurrentAsCompared() {
        guard let mole = currentMole else { return }
        comparedMoles.insert(mole.id)
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
        
        // If we've reached the end, finish comparison
        if currentMoleIndex >= molesToCompare.count {
            finishComparison()
        }
    }
    
    /// Go back to previous mole
    func goToPrevious() {
        if currentMoleIndex > 0 {
            currentMoleIndex -= 1
            
            // Remove from compared/skipped if going back
            if let mole = currentMole {
                comparedMoles.remove(mole.id)
                skippedMoles.remove(mole.id)
            }
        }
    }
    
    /// Finish comparison session
    func finishComparison() {
        isComparing = false
        currentMoleIndex = 0
        molesToCompare.removeAll()
        // Keep originalTotalCount for summary display
    }
    
    /// Cancel comparison session
    func cancelComparison() {
        isComparing = false
        currentMoleIndex = 0
        comparedMoles.removeAll()
        skippedMoles.removeAll()
        molesToCompare.removeAll()
        originalTotalCount = 0
    }
}