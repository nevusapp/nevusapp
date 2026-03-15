//
//  Mole.swift
//  Nevus
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
    
    // Location markers linking this mole to overview images
    @Relationship(deleteRule: .cascade)
    var locationMarkers: [MoleLocationMarker]
    
    init(bodyRegion: String = "Unbekannt", bodySide: String = "Mitte") {
        self.id = UUID()
        self.createdAt = Date()
        self.lastModified = Date()
        self.bodyRegion = bodyRegion
        self.bodySide = bodySide
        self.notes = ""
        self.referenceImageID = nil
        self.images = []
        self.locationMarkers = []
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
    case head
    case neck
    case armLeft
    case armRight
    case chest
    case abdomen
    case pelvis
    case backUpper
    case backMiddle
    case backLower
    case legLeft
    case legRight
    
    var id: String { rawValue }
    
    // Localized display name
    var localizedName: String {
        switch self {
        case .head: return String(localized: "body_region_head")
        case .neck: return String(localized: "body_region_neck")
        case .armLeft: return String(localized: "body_region_arm_left")
        case .armRight: return String(localized: "body_region_arm_right")
        case .chest: return String(localized: "body_region_chest")
        case .abdomen: return String(localized: "body_region_abdomen")
        case .pelvis: return String(localized: "body_region_pelvis")
        case .backUpper: return String(localized: "body_region_back_upper")
        case .backMiddle: return String(localized: "body_region_back_middle")
        case .backLower: return String(localized: "body_region_back_lower")
        case .legLeft: return String(localized: "body_region_leg_left")
        case .legRight: return String(localized: "body_region_leg_right")
        }
    }
    
    // Initialize from string value
    static func from(value: String) -> BodyRegion {
        return BodyRegion(rawValue: value) ?? .head
    }
    
    // Order for display in grouped list
    static var displayOrder: [BodyRegion] {
        [.head, .neck, .armLeft, .armRight, .chest, .abdomen, .pelvis, .backUpper, .backMiddle, .backLower, .legLeft, .legRight]
    }
    
    // Sorting order from top to bottom of body (for guided scanning/comparison)
    var sortOrder: Int {
        switch self {
        case .head: return 0
        case .neck: return 1
        case .armLeft: return 2
        case .armRight: return 3
        case .chest: return 4
        case .abdomen: return 5
        case .pelvis: return 6
        case .backUpper: return 7
        case .backMiddle: return 8
        case .backLower: return 9
        case .legLeft: return 10
        case .legRight: return 11
        }
    }
}

// MARK: - Body Side Enum
enum BodySide: String, CaseIterable, Identifiable {
    // Head specific
    case headTop
    case headFront
    case headLeft
    case headRight
    case headBack
    
    // Neck specific
    case neckFront
    case neckLeft
    case neckRight
    case neckBack
    
    // Torso (Chest, Abdomen, Pelvis, Back, Buttocks)
    case torsoLeft
    case torsoCenter
    case torsoRight
    
    // Arms
    case armUpperFront
    case armUpperBack
    case armLowerInner
    case armLowerOuter
    case handInner
    case handOuter
    
    // Legs
    case legThighFront
    case legThighBack
    case legThighInner
    case legThighOuter
    case legCalfFront
    case legCalfBack
    case legCalfInner
    case legCalfOuter
    case footTop
    case footSole
    
    var id: String { rawValue }
    
    // Localized display text
    var displayText: String {
        switch self {
        case .headTop: return String(localized: "body_side_head_top")
        case .headFront: return String(localized: "body_side_head_front")
        case .headLeft: return String(localized: "body_side_head_left")
        case .headRight: return String(localized: "body_side_head_right")
        case .headBack: return String(localized: "body_side_head_back")
        case .neckFront: return String(localized: "body_side_neck_front")
        case .neckLeft: return String(localized: "body_side_neck_left")
        case .neckRight: return String(localized: "body_side_neck_right")
        case .neckBack: return String(localized: "body_side_neck_back")
        case .torsoLeft: return String(localized: "body_side_torso_left")
        case .torsoCenter: return String(localized: "body_side_torso_center")
        case .torsoRight: return String(localized: "body_side_torso_right")
        case .armUpperFront: return String(localized: "body_side_arm_upper_front")
        case .armUpperBack: return String(localized: "body_side_arm_upper_back")
        case .armLowerInner: return String(localized: "body_side_arm_lower_inner")
        case .armLowerOuter: return String(localized: "body_side_arm_lower_outer")
        case .handInner: return String(localized: "body_side_hand_inner")
        case .handOuter: return String(localized: "body_side_hand_outer")
        case .legThighFront: return String(localized: "body_side_leg_thigh_front")
        case .legThighBack: return String(localized: "body_side_leg_thigh_back")
        case .legThighInner: return String(localized: "body_side_leg_thigh_inner")
        case .legThighOuter: return String(localized: "body_side_leg_thigh_outer")
        case .legCalfFront: return String(localized: "body_side_leg_calf_front")
        case .legCalfBack: return String(localized: "body_side_leg_calf_back")
        case .legCalfInner: return String(localized: "body_side_leg_calf_inner")
        case .legCalfOuter: return String(localized: "body_side_leg_calf_outer")
        case .footTop: return String(localized: "body_side_foot_top")
        case .footSole: return String(localized: "body_side_foot_sole")
        }
    }
    
    // Initialize from string value
    static func from(value: String) -> BodySide? {
        return BodySide(rawValue: value)
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