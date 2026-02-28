//
//  SyncPackage.swift
//  MoleTracker
//
//  Created on 28.02.2026.
//

import Foundation

/// Represents a sync package for transferring mole data between devices
struct SyncPackage: Codable {
    let version: Int = 1
    let exportDate: Date
    let sinceDate: Date
    let moles: [MoleData]
    let images: [ImageData]
    
    struct MoleData: Codable {
        let id: String
        let createdAt: Date
        let lastModified: Date
        let bodyRegion: String
        let bodySide: String
        let notes: String
        let referenceImageID: String?
        let imageIDs: [String]
    }
    
    struct ImageData: Codable {
        let id: String
        let captureDate: Date
        let imageWidth: Int
        let imageHeight: Int
        let moleID: String
        let filename: String // Reference to image file in package
    }
    
    /// Create a sync package from moles and images
    static func create(moles: [MoleExportData], images: [ImageExportData], sinceDate: Date) -> SyncPackage {
        let moleData = moles.map { mole in
            MoleData(
                id: mole.id,
                createdAt: mole.createdAt,
                lastModified: mole.lastModified,
                bodyRegion: mole.bodyRegion,
                bodySide: mole.bodySide,
                notes: mole.notes,
                referenceImageID: mole.referenceImageID,
                imageIDs: mole.imageIDs
            )
        }
        
        let imageData = images.map { image in
            ImageData(
                id: image.id,
                captureDate: image.captureDate,
                imageWidth: image.imageWidth,
                imageHeight: image.imageHeight,
                moleID: image.moleID,
                filename: image.filename
            )
        }
        
        return SyncPackage(
            exportDate: Date(),
            sinceDate: sinceDate,
            moles: moleData,
            images: imageData
        )
    }
}

/// Temporary structure for exporting mole data
struct MoleExportData {
    let id: String
    let createdAt: Date
    let lastModified: Date
    let bodyRegion: String
    let bodySide: String
    let notes: String
    let referenceImageID: String?
    let imageIDs: [String]
}

/// Temporary structure for exporting image data
struct ImageExportData {
    let id: String
    let captureDate: Date
    let imageWidth: Int
    let imageHeight: Int
    let moleID: String
    let filename: String
}