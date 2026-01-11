//
//  MoleLocationMarker.swift
//  MoleTracker
//
//  Created on 11.01.2026.
//

import Foundation
import SwiftData

@Model
final class MoleLocationMarker {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    
    // Position on the overview image (normalized coordinates 0.0 to 1.0)
    var normalizedX: Double
    var normalizedY: Double
    
    // Optional label/note for this marker
    var label: String
    
    // Relationships
    var mole: Mole?
    var overviewImage: BodyRegionOverview?
    
    init(normalizedX: Double, normalizedY: Double, label: String = "") {
        self.id = UUID()
        self.createdAt = Date()
        self.normalizedX = normalizedX
        self.normalizedY = normalizedY
        self.label = label
    }
}