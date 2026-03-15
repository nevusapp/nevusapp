//
//  ExportService.swift
//  Nevus
//
//  Created on 10.01.2026.
//

import Foundation
import UIKit
import UniformTypeIdentifiers
import SwiftData

class ExportService {
    
    /// Export a single mole with all its images and metadata
    static func exportMole(_ mole: Mole) -> URL? {
        let fileManager = FileManager.default
        
        // Use Documents directory instead of temp for better access
        guard let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let exportDir = documentsDir.appendingPathComponent("MoleExport_\(UUID().uuidString)")
        
        // Ensure cleanup always happens, even on error
        defer {
            do {
                if fileManager.fileExists(atPath: exportDir.path) {
                    try fileManager.removeItem(at: exportDir)
                }
            } catch {
                print("⚠️ Cleanup failed for \(exportDir.path): \(error.localizedDescription)")
            }
        }
        
        do {
            try fileManager.createDirectory(at: exportDir, withIntermediateDirectories: true)
            
            // Create metadata file
            let metadata = createMetadata(for: mole)
            let metadataURL = exportDir.appendingPathComponent("metadata.json")
            try metadata.write(to: metadataURL, atomically: true, encoding: .utf8)
            
            // Export all images
            for (index, image) in mole.images.enumerated() {
                if let uiImage = image.uiImage {
                    let imageURL = exportDir.appendingPathComponent("image_\(index + 1).jpg")
                    if let jpegData = uiImage.jpegData(compressionQuality: 0.9) {
                        try jpegData.write(to: imageURL)
                    }
                    
                    // Create individual image metadata
                    let imageMetadata = createImageMetadata(for: image, mole: mole, index: index + 1)
                    let imageMetadataURL = exportDir.appendingPathComponent("image_\(index + 1)_metadata.json")
                    try imageMetadata.write(to: imageMetadataURL, atomically: true, encoding: .utf8)
                }
            }
            
            // Create ZIP archive in Documents directory
            let zipURL = documentsDir.appendingPathComponent("MoleExport_\(mole.id.uuidString).zip")
            try zipDirectory(at: exportDir, to: zipURL)
            
            return zipURL
        } catch {
            print("❌ Export error: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Export all moles
    static func exportAllMoles(_ moles: [Mole]) -> URL? {
        let fileManager = FileManager.default
        
        // Use Documents directory instead of temp for better access
        guard let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let exportDir = documentsDir.appendingPathComponent("AllMolesExport_\(UUID().uuidString)")
        
        // Ensure cleanup always happens, even on error
        defer {
            do {
                if fileManager.fileExists(atPath: exportDir.path) {
                    try fileManager.removeItem(at: exportDir)
                }
            } catch {
                print("⚠️ Cleanup failed for \(exportDir.path): \(error.localizedDescription)")
            }
        }
        
        do {
            try fileManager.createDirectory(at: exportDir, withIntermediateDirectories: true)
            
            // Create summary metadata
            let summary = createSummaryMetadata(for: moles)
            let summaryURL = exportDir.appendingPathComponent("summary.json")
            try summary.write(to: summaryURL, atomically: true, encoding: .utf8)
            
            // Export each mole in its own folder
            for (moleIndex, mole) in moles.enumerated() {
                let moleDir = exportDir.appendingPathComponent("Mole_\(moleIndex + 1)_\(mole.bodyRegion)")
                try fileManager.createDirectory(at: moleDir, withIntermediateDirectories: true)
                
                // Mole metadata
                let metadata = createMetadata(for: mole)
                let metadataURL = moleDir.appendingPathComponent("metadata.json")
                try metadata.write(to: metadataURL, atomically: true, encoding: .utf8)
                
                // Export images
                for (imageIndex, image) in mole.images.enumerated() {
                    if let uiImage = image.uiImage {
                        let imageURL = moleDir.appendingPathComponent("image_\(imageIndex + 1).jpg")
                        if let jpegData = uiImage.jpegData(compressionQuality: 0.9) {
                            try jpegData.write(to: imageURL)
                        }
                        
                        let imageMetadata = createImageMetadata(for: image, mole: mole, index: imageIndex + 1)
                        let imageMetadataURL = moleDir.appendingPathComponent("image_\(imageIndex + 1)_metadata.json")
                        try imageMetadata.write(to: imageMetadataURL, atomically: true, encoding: .utf8)
                    }
                }
            }
            
            // Create ZIP archive in Documents directory
            let zipURL = documentsDir.appendingPathComponent("AllMoles_\(Date().formatted(date: .numeric, time: .omitted)).zip")
            try zipDirectory(at: exportDir, to: zipURL)
            
            return zipURL
        } catch {
            print("❌ Export error: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Export a single image as JPEG
    static func exportImage(_ image: MoleImage) -> URL? {
        guard let uiImage = image.uiImage else {
            return nil
        }
        
        let fileManager = FileManager.default
        
        // Use Documents directory for better access
        guard let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        // Create filename with date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateString = dateFormatter.string(from: image.captureDate)
        
        let filename = "Mole_\(dateString).jpg"
        let imageURL = documentsDir.appendingPathComponent(filename)
        
        // Export as JPEG with high quality
        if let jpegData = uiImage.jpegData(compressionQuality: 0.95) {
            do {
                try jpegData.write(to: imageURL)
                return imageURL
            } catch {
                print("Image export error: \(error)")
                return nil
            }
        }
        
        return nil
    }
    
    // MARK: - Metadata Creation
    
    private static func createMetadata(for mole: Mole) -> String {
        let metadata: [String: Any] = [
            "id": mole.id.uuidString,
            "bodyRegion": mole.bodyRegion,
            "bodySide": mole.bodySide,
            "notes": mole.notes,
            "createdAt": ISO8601DateFormatter().string(from: mole.createdAt),
            "lastModified": ISO8601DateFormatter().string(from: mole.lastModified),
            "imageCount": mole.imageCount
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: metadata, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        return "{}"
    }
    
    private static func createImageMetadata(for image: MoleImage, mole: Mole, index: Int) -> String {
        let metadata: [String: Any] = [
            "imageNumber": index,
            "id": image.id.uuidString,
            "captureDate": ISO8601DateFormatter().string(from: image.captureDate),
            "dimensions": [
                "width": image.imageWidth,
                "height": image.imageHeight
            ],
            "moleInfo": [
                "bodyRegion": mole.bodyRegion,
                "bodySide": mole.bodySide,
                "notes": mole.notes
            ]
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: metadata, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        return "{}"
    }
    
    private static func createSummaryMetadata(for moles: [Mole]) -> String {
        let metadata: [String: Any] = [
            "exportDate": ISO8601DateFormatter().string(from: Date()),
            "totalMoles": moles.count,
            "totalImages": moles.reduce(0) { $0 + $1.imageCount },
            "moles": moles.map { mole in
                [
                    "id": mole.id.uuidString,
                    "bodyRegion": mole.bodyRegion,
                    "bodySide": mole.bodySide,
                    "imageCount": mole.imageCount,
                    "createdAt": ISO8601DateFormatter().string(from: mole.createdAt)
                ]
            }
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: metadata, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        return "{}"
    }
    
    // MARK: - ZIP Creation
    
    private static func zipDirectory(at sourceURL: URL, to destinationURL: URL) throws {
        let fileManager = FileManager.default
        
        // Remove existing zip if it exists
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        
        // Use NSFileCoordinator for safe file access
        var error: NSError?
        NSFileCoordinator().coordinate(readingItemAt: sourceURL, options: [.forUploading], error: &error) { zipURL in
            do {
                try fileManager.copyItem(at: zipURL, to: destinationURL)
            } catch {
                print("ZIP creation error: \(error)")
            }
        }
        
        if let error = error {
            throw error
        }
    }
    
    // MARK: - Delta Sync Export
    
    /// Export moles, images, and overviews created/modified since a specific date
    static func exportDeltaSync(moles: [Mole], overviews: [BodyRegionOverview], sinceDate: Date) -> URL? {
        let fileManager = FileManager.default
        
        guard let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let exportDir = documentsDir.appendingPathComponent("SyncExport_\(UUID().uuidString)")
        
        do {
            try fileManager.createDirectory(at: exportDir, withIntermediateDirectories: true)
            
            // Filter moles, images, and overviews by date
            let filteredData = filterDataSinceDate(moles: moles, overviews: overviews, sinceDate: sinceDate)
            
            guard !filteredData.moles.isEmpty || !filteredData.images.isEmpty || !filteredData.overviews.isEmpty else {
                print("ℹ️ No new data to sync since \(sinceDate)")
                return nil
            }
            
            // Create sync package metadata
            let syncPackage = SyncPackage.create(
                moles: filteredData.moles,
                images: filteredData.images,
                overviews: filteredData.overviews,
                sinceDate: sinceDate
            )
            
            // Write manifest
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let manifestData = try encoder.encode(syncPackage)
            let manifestURL = exportDir.appendingPathComponent("manifest.json")
            try manifestData.write(to: manifestURL)
            
            // Create images directory
            let imagesDir = exportDir.appendingPathComponent("images")
            try fileManager.createDirectory(at: imagesDir, withIntermediateDirectories: true)
            
            // Export mole image files
            for imageData in filteredData.images {
                if let mole = moles.first(where: { $0.id.uuidString == imageData.moleID }),
                   let image = mole.images.first(where: { $0.id.uuidString == imageData.id }),
                   let uiImage = image.uiImage {
                    
                    let imageURL = imagesDir.appendingPathComponent(imageData.filename)
                    if let jpegData = uiImage.jpegData(compressionQuality: 0.9) {
                        try jpegData.write(to: imageURL)
                    }
                }
            }
            
            // Create overviews directory
            let overviewsDir = exportDir.appendingPathComponent("overviews")
            try fileManager.createDirectory(at: overviewsDir, withIntermediateDirectories: true)
            
            // Export overview image files
            for overviewData in filteredData.overviews {
                if let overview = overviews.first(where: { $0.id.uuidString == overviewData.id }),
                   let uiImage = overview.uiImage {
                    
                    let imageURL = overviewsDir.appendingPathComponent(overviewData.filename)
                    if let jpegData = uiImage.jpegData(compressionQuality: 0.9) {
                        try jpegData.write(to: imageURL)
                    }
                }
            }
            
            // Create package bundle (directory with .moletracker extension)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: sinceDate)
            let packageURL = documentsDir.appendingPathComponent("MoleSync_since_\(dateString).moletracker")
            
            // Remove existing package if it exists
            if fileManager.fileExists(atPath: packageURL.path) {
                try fileManager.removeItem(at: packageURL)
            }
            
            // Move the export directory to the package URL
            // This creates a directory bundle that iOS treats as a single file
            try fileManager.moveItem(at: exportDir, to: packageURL)
            
            return packageURL
        } catch {
            print("❌ Delta sync export error: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Filter moles, images, and overviews by date
    private static func filterDataSinceDate(moles: [Mole], overviews: [BodyRegionOverview], sinceDate: Date) -> (moles: [MoleExportData], images: [ImageExportData], overviews: [OverviewExportData]) {
        var exportMoles: [MoleExportData] = []
        var exportImages: [ImageExportData] = []
        var exportOverviews: [OverviewExportData] = []
        var processedMoleIDs = Set<String>()
        
        // Filter moles and images
        for mole in moles {
            // Get images created/modified since date
            let newImages = mole.images.filter { $0.captureDate >= sinceDate }
            
            if !newImages.isEmpty {
                // Include mole if it has new images
                let moleID = mole.id.uuidString
                
                // Only add mole once
                if !processedMoleIDs.contains(moleID) {
                    let moleData = MoleExportData(
                        id: moleID,
                        createdAt: mole.createdAt,
                        lastModified: mole.lastModified,
                        bodyRegion: mole.bodyRegion,
                        bodySide: mole.bodySide,
                        notes: mole.notes,
                        referenceImageID: mole.referenceImageID?.uuidString,
                        imageIDs: mole.images.map { $0.id.uuidString }
                    )
                    exportMoles.append(moleData)
                    processedMoleIDs.insert(moleID)
                }
                
                // Add new images
                for image in newImages {
                    let imageData = ImageExportData(
                        id: image.id.uuidString,
                        captureDate: image.captureDate,
                        imageWidth: image.imageWidth,
                        imageHeight: image.imageHeight,
                        moleID: moleID,
                        filename: "\(image.id.uuidString).jpg"
                    )
                    exportImages.append(imageData)
                }
            }
        }
        
        // Filter overviews
        for overview in overviews where overview.captureDate >= sinceDate {
            let markers = overview.locationMarkers.compactMap { marker -> LocationMarkerExportData? in
                guard let mole = marker.mole else { return nil }
                return LocationMarkerExportData(
                    id: marker.id.uuidString,
                    moleID: mole.id.uuidString,
                    x: marker.normalizedX,
                    y: marker.normalizedY
                )
            }
            
            let overviewData = OverviewExportData(
                id: overview.id.uuidString,
                bodyRegion: overview.bodyRegion,
                captureDate: overview.captureDate,
                notes: overview.notes,
                pitch: overview.pitch,
                roll: overview.roll,
                yaw: overview.yaw,
                barometricPressure: overview.barometricPressure,
                altitude: overview.altitude,
                filename: "\(overview.id.uuidString).jpg",
                locationMarkers: markers
            )
            exportOverviews.append(overviewData)
        }
        
        return (moles: exportMoles, images: exportImages, overviews: exportOverviews)
    }
}
