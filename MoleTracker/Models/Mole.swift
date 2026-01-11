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
    // Head specific
    case headTop = "Kopf: Oben"
    case headFront = "Kopf: Vorne/Gesicht"
    case headLeft = "Kopf: Links"
    case headRight = "Kopf: Rechts"
    case headBack = "Kopf: Hinten"
    
    // Neck specific
    case neckFront = "Hals: Vorne"
    case neckLeft = "Hals: Links"
    case neckRight = "Hals: Rechts"
    case neckBack = "Hals: Hinten"
    
    // Torso (Chest, Abdomen, Pelvis, Back, Buttocks)
    case torsoLeft = "Links"
    case torsoCenter = "Mitte"
    case torsoRight = "Rechts"
    
    // Arms
    case armUpperFront = "Oberarm-Vorne (Bizeps)"
    case armUpperBack = "Oberarm-Hinten (Trizeps)"
    case armLowerInner = "Unterarm-Innen"
    case armLowerOuter = "Unterarm-Aussen"
    case handInner = "Hand-Innen"
    case handOuter = "Hand-Aussen"
    
    // Legs
    case legThighFront = "Oberschenkel-Vorne"
    case legThighBack = "Oberschenkel-Hinten"
    case legThighInner = "Oberschenkel-Innen"
    case legThighOuter = "Oberschenkel-Aussen"
    case legCalfFront = "Unterschenkel-Vorne (Schienbein)"
    case legCalfBack = "Unterschenkel-Hinten (Wade)"
    case legCalfInner = "Unterschenkel-Innen"
    case legCalfOuter = "Unterschenkel-Aussen"
    case footTop = "Fuss-Oben"
    case footSole = "Fusssohle"
    
    var id: String { rawValue }
    
    // Display text without region prefix for cleaner UI
    var displayText: String {
        switch self {
        case .headTop: return "Oben"
        case .headFront: return "Vorne/Gesicht"
        case .headLeft: return "Links"
        case .headRight: return "Rechts"
        case .headBack: return "Hinten"
        case .neckFront: return "Vorne"
        case .neckLeft: return "Links"
        case .neckRight: return "Rechts"
        case .neckBack: return "Hinten"
        default: return rawValue
        }
    }
    
    // Get available sides for a specific body region
    static func availableSides(for region: BodyRegion) -> [BodySide] {
        switch region {
        case .head:
            return [.headTop, .headFront, .headLeft, .headRight, .headBack]
            
        case .neck:
            return [.neckFront, .neckLeft, .neckRight, .neckBack]
            
        case .chest, .abdomen, .pelvis, .backUpper, .backMiddle, .backLower:
            return [.torsoLeft, .torsoCenter, .torsoRight]
            
        case .armLeft, .armRight:
            return [.armUpperFront, .armUpperBack, .armLowerInner, .armLowerOuter, .handInner, .handOuter]
            
        case .legLeft, .legRight:
            return [.legThighFront, .legThighBack, .legThighInner, .legThighOuter,
                    .legCalfFront, .legCalfBack, .legCalfInner, .legCalfOuter,
                    .footTop, .footSole]
        }
    }
    
    // Get default side for a region
    static func defaultSide(for region: BodyRegion) -> BodySide {
        switch region {
        case .head:
            return .headFront
        case .neck:
            return .neckFront
        case .chest, .abdomen, .pelvis, .backUpper, .backMiddle, .backLower:
            return .torsoCenter
        case .armLeft, .armRight:
            return .armUpperFront
        case .legLeft, .legRight:
            return .legThighFront
        }
    }
}