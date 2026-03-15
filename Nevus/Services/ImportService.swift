//
//  ImportService.swift
//  Nevus
//
//  Created on 28.02.2026.
//

import Foundation
import SwiftData
import UIKit

@MainActor
class ImportService {
    
    /// Import result with statistics
    struct ImportResult {
        let molesImported: Int
        let imagesImported: Int
        let overviewsImported: Int
        let molesSkipped: Int
        let imagesSkipped: Int
        let overviewsSkipped: Int
        let errors: [String]
        
        var hasNewData: Bool {
            molesImported > 0 || imagesImported > 0 || overviewsImported > 0
        }
        
        var summary: String {
            var parts: [String] = []
            if molesImported > 0 {
                parts.append("\(molesImported) mole(s)")
            }
            if imagesImported > 0 {
                parts.append("\(imagesImported) image(s)")
            }
            if overviewsImported > 0 {
                parts.append("\(overviewsImported) overview(s)")
            }
            if molesSkipped > 0 {
                parts.append("\(molesSkipped) duplicate mole(s) skipped")
            }
            if imagesSkipped > 0 {
                parts.append("\(imagesSkipped) duplicate image(s) skipped")
            }
            if overviewsSkipped > 0 {
                parts.append("\(overviewsSkipped) duplicate overview(s) skipped")
            }
            return parts.joined(separator: ", ")
        }
    }
    
    /// Import a sync package from a URL
    static func importSyncPackage(from url: URL, modelContext: ModelContext) async throws -> ImportResult {
        // The .nevus file is actually a directory bundle
        // Read manifest directly from it
        let manifestURL = url.appendingPathComponent("manifest.json")
        let manifestData = try Data(contentsOf: manifestURL)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let syncPackage = try decoder.decode(SyncPackage.self, from: manifestData)
        
        // Validate version
        guard syncPackage.version == 1 else {
            throw ImportError.unsupportedVersion(syncPackage.version)
        }
        
        // Import data - images and overviews are in subdirectories
        let imagesDir = url.appendingPathComponent("images")
        let overviewsDir = url.appendingPathComponent("overviews")
        return try await importData(syncPackage: syncPackage, imagesDir: imagesDir, overviewsDir: overviewsDir, modelContext: modelContext)
    }
    
    /// Import moles, images, and overviews from sync package
    private static func importData(syncPackage: SyncPackage, imagesDir: URL, overviewsDir: URL, modelContext: ModelContext) async throws -> ImportResult {
        var molesImported = 0
        var imagesImported = 0
        var overviewsImported = 0
        var molesSkipped = 0
        var imagesSkipped = 0
        var overviewsSkipped = 0
        var errors: [String] = []
        
        // Fetch existing moles and images to check for duplicates
        let existingMoles = try modelContext.fetch(FetchDescriptor<Mole>())
        let existingMoleIDs = Set(existingMoles.map { $0.id.uuidString })
        
        let existingImages = try modelContext.fetch(FetchDescriptor<MoleImage>())
        let existingImageIDs = Set(existingImages.map { $0.id.uuidString })
        
        // Create a map of mole ID to Mole object for quick lookup
        var moleMap: [String: Mole] = [:]
        for mole in existingMoles {
            moleMap[mole.id.uuidString] = mole
        }
        
        // Import moles
        for moleData in syncPackage.moles {
            if existingMoleIDs.contains(moleData.id) {
                // Mole already exists, update it if needed
                if let existingMole = moleMap[moleData.id] {
                    // Update mole metadata if it's newer
                    if moleData.lastModified > existingMole.lastModified {
                        existingMole.notes = moleData.notes
                        existingMole.lastModified = moleData.lastModified
                        if let refID = moleData.referenceImageID {
                            existingMole.referenceImageID = UUID(uuidString: refID)
                        }
                    }
                }
                molesSkipped += 1
            } else {
                // Create new mole
                let newMole = Mole(bodyRegion: moleData.bodyRegion, bodySide: moleData.bodySide)
                newMole.id = UUID(uuidString: moleData.id) ?? UUID()
                newMole.createdAt = moleData.createdAt
                newMole.lastModified = moleData.lastModified
                newMole.notes = moleData.notes
                if let refID = moleData.referenceImageID {
                    newMole.referenceImageID = UUID(uuidString: refID)
                }
                
                modelContext.insert(newMole)
                moleMap[moleData.id] = newMole
                molesImported += 1
            }
        }
        
        // Import images
        for imageData in syncPackage.images {
            if existingImageIDs.contains(imageData.id) {
                imagesSkipped += 1
                continue
            }
            
            // Find the mole for this image
            guard let mole = moleMap[imageData.moleID] else {
                errors.append("Mole not found for image \(imageData.id)")
                continue
            }
            
            // Load image file
            let imageURL = imagesDir.appendingPathComponent(imageData.filename)
            guard let imageFileData = try? Data(contentsOf: imageURL),
                  let uiImage = UIImage(data: imageFileData) else {
                errors.append("Failed to load image file: \(imageData.filename)")
                continue
            }
            
            // Create MoleImage
            guard let moleImage = MoleImage(image: uiImage) else {
                errors.append("Failed to create MoleImage from: \(imageData.filename)")
                continue
            }
            
            // Set properties from metadata
            moleImage.id = UUID(uuidString: imageData.id) ?? UUID()
            moleImage.captureDate = imageData.captureDate
            moleImage.imageWidth = imageData.imageWidth
            moleImage.imageHeight = imageData.imageHeight
            
            // Link to mole
            moleImage.mole = mole
            mole.images.append(moleImage)
            
            modelContext.insert(moleImage)
            imagesImported += 1
        }
        
        // Import overviews
        let existingOverviews = try modelContext.fetch(FetchDescriptor<BodyRegionOverview>())
        let existingOverviewIDs = Set(existingOverviews.map { $0.id.uuidString })
        
        for overviewData in syncPackage.overviews {
            if existingOverviewIDs.contains(overviewData.id) {
                overviewsSkipped += 1
                continue
            }
            
            // Load overview image file
            let imageURL = overviewsDir.appendingPathComponent(overviewData.filename)
            guard let imageFileData = try? Data(contentsOf: imageURL),
                  let uiImage = UIImage(data: imageFileData) else {
                errors.append("Failed to load overview image: \(overviewData.filename)")
                continue
            }
            
            // Create BodyRegionOverview
            let overview = BodyRegionOverview(bodyRegion: overviewData.bodyRegion, image: uiImage)
            overview.id = UUID(uuidString: overviewData.id) ?? UUID()
            overview.captureDate = overviewData.captureDate
            overview.notes = overviewData.notes
            overview.pitch = overviewData.pitch
            overview.roll = overviewData.roll
            overview.yaw = overviewData.yaw
            overview.barometricPressure = overviewData.barometricPressure
            overview.altitude = overviewData.altitude
            
            // Import location markers
            for markerData in overviewData.locationMarkers {
                // Find the mole for this marker
                if let mole = moleMap[markerData.moleID] {
                    let marker = MoleLocationMarker(
                        normalizedX: markerData.x,
                        normalizedY: markerData.y
                    )
                    marker.id = UUID(uuidString: markerData.id) ?? UUID()
                    marker.mole = mole
                    marker.overviewImage = overview
                    overview.locationMarkers.append(marker)
                    modelContext.insert(marker)
                }
            }
            
            modelContext.insert(overview)
            overviewsImported += 1
        }
        
        // Save context
        try modelContext.save()
        
        return ImportResult(
            molesImported: molesImported,
            imagesImported: imagesImported,
            overviewsImported: overviewsImported,
            molesSkipped: molesSkipped,
            imagesSkipped: imagesSkipped,
            overviewsSkipped: overviewsSkipped,
            errors: errors
        )
    }
}

// MARK: - Import Errors

enum ImportError: LocalizedError {
    case unsupportedVersion(Int)
    case invalidPackage
    case missingManifest
    
    var errorDescription: String? {
        switch self {
        case .unsupportedVersion(let version):
            return "Unsupported package version: \(version)"
        case .invalidPackage:
            return "Invalid sync package format"
        case .missingManifest:
            return "Package manifest not found"
        }
    }
}