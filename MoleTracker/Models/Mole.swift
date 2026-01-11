//
//  Mole.swift
//  MoleTracker
//
//  Created on 06.01.2026.
//

import Foundation
import SwiftData

@Model
final class Mole {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var lastModified: Date
    var bodyRegion: String
    var bodySide: String
    var notes: String
    
    // Reference image ID for overlay mode (defaults to oldest image)
    var referenceImageID: UUID?
    
    @Relationship(deleteRule: .cascade)
    var images: [MoleImage]
    
    init(bodyRegion: String = "Unbekannt", bodySide: String = "Mitte") {
        self.id = UUID()
        self.createdAt = Date()
        self.lastModified = Date()
        self.bodyRegion = bodyRegion
        self.bodySide = bodySide
        self.notes = ""
        self.referenceImageID = nil
        self.images = []
    }
    
    var imageCount: Int {
        images.count
    }
    
    var latestImage: MoleImage? {
        images.sorted(by: { $0.captureDate > $1.captureDate }).first
    }
    
    // Get the reference image for overlay mode
    var referenceImage: MoleImage? {
        // If a specific reference is set, use it
        if let refID = referenceImageID,
           let image = images.first(where: { $0.id == refID }) {
            return image
        }
        
        // Otherwise, default to the oldest image (first captured)
        return images.sorted(by: { $0.captureDate < $1.captureDate }).first
    }
    
    // Set a specific image as reference for overlay
    func setReferenceImage(_ image: MoleImage) {
        self.referenceImageID = image.id
        updateModifiedDate()
    }
    
    // Clear reference image (will default to oldest)
    func clearReferenceImage() {
        self.referenceImageID = nil
        updateModifiedDate()
    }
    
    func updateModifiedDate() {
        self.lastModified = Date()
    }
}

// MARK: - Body Region Enum
enum BodyRegion: String, CaseIterable, Identifiable {
    case head = "Kopf"
    case neck = "Hals"
    case armLeft = "Arm/Hand links"
    case armRight = "Arm/Hand rechts"
    case chest = "Brust"
    case abdomen = "Bauch"
    case pelvis = "Becken"
    case backUpper = "Rücken oben (BWS)"
    case backMiddle = "Rücken Mitte (LWS)"
    case backLower = "Rücken unten (Kreuz/Gesäss)"
    case legLeft = "Bein/Fuss links"
    case legRight = "Bein/Fuss rechts"
    
    var id: String { rawValue }
    
    // Order for display in grouped list
    static var displayOrder: [BodyRegion] {
        [.head, .neck, .armLeft, .armRight, .chest, .abdomen, .pelvis, .backUpper, .backMiddle, .backLower, .legLeft, .legRight]
    }
}

// MARK: - Body Side Enum
enum BodySide: String, CaseIterable, Identifiable {
    case left = "Links"
    case right = "Rechts"
    case center = "Mitte"
    case back = "Rücken"
    
    var id: String { rawValue }
}