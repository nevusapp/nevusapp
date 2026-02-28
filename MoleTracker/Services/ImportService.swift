//
//  ImportService.swift
//  MoleTracker
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
        let molesSkipped: Int
        let imagesSkipped: Int
        let errors: [String]
        
        var hasNewData: Bool {
            molesImported > 0 || imagesImported > 0
        }
        
        var summary: String {
            var parts: [String] = []
            if molesImported > 0 {
                parts.append("\(molesImported) mole(s)")
            }
            if imagesImported > 0 {
                parts.append("\(imagesImported) image(s)")
            }
            if molesSkipped > 0 {
                parts.append("\(molesSkipped) duplicate mole(s) skipped")
            }
            if imagesSkipped > 0 {
                parts.append("\(imagesSkipped) duplicate image(s) skipped")
            }
            return parts.joined(separator: ", ")
        }
    }
    
    /// Import a sync package from a URL
    static func importSyncPackage(from url: URL, modelContext: ModelContext) async throws -> ImportResult {
        let fileManager = FileManager.default
        
        // Create temporary directory for extraction
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? fileManager.removeItem(at: tempDir)
        }
        
        // Unzip the package
        try await unzipPackage(from: url, to: tempDir)
        
        // Read manifest
        let manifestURL = tempDir.appendingPathComponent("manifest.json")
        let manifestData = try Data(contentsOf: manifestURL)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let syncPackage = try decoder.decode(SyncPackage.self, from: manifestData)
        
        // Validate version
        guard syncPackage.version == 1 else {
            throw ImportError.unsupportedVersion(syncPackage.version)
        }
        
        // Import data
        return try await importData(syncPackage: syncPackage, imagesDir: tempDir.appendingPathComponent("images"), modelContext: modelContext)
    }
    
    /// Unzip package to temporary directory
    private static func unzipPackage(from sourceURL: URL, to destinationURL: URL) async throws {
        let fileManager = FileManager.default
        
        // Use NSFileCoordinator for safe file access
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            var coordinatorError: NSError?
            NSFileCoordinator().coordinate(readingItemAt: sourceURL, options: [.forUploading], error: &coordinatorError) { zipURL in
                do {
                    // The zipURL is actually a directory created by the system
                    // Copy its contents to our destination
                    let contents = try fileManager.contentsOfDirectory(at: zipURL, includingPropertiesForKeys: nil)
                    for item in contents {
                        let destItem = destinationURL.appendingPathComponent(item.lastPathComponent)
                        try fileManager.copyItem(at: item, to: destItem)
                    }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            
            if let error = coordinatorError {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Import moles and images from sync package
    private static func importData(syncPackage: SyncPackage, imagesDir: URL, modelContext: ModelContext) async throws -> ImportResult {
        var molesImported = 0
        var imagesImported = 0
        var molesSkipped = 0
        var imagesSkipped = 0
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
        
        // Save context
        try modelContext.save()
        
        return ImportResult(
            molesImported: molesImported,
            imagesImported: imagesImported,
            molesSkipped: molesSkipped,
            imagesSkipped: imagesSkipped,
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