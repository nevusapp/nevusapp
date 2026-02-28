//
//  SyncPackage.swift
//  MoleTracker
//
//  Created on 28.02.2026.
//

import Foundation

/// Represents a sync package for transferring mole data between devices
struct SyncPackage: Codable {
    let version: Int
    let exportDate: Date
    let sinceDate: Date
    let moles: [MoleData]
    let images: [ImageData]
    let overviews: [OverviewData]
    
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
    
    struct OverviewData: Codable {
        let id: String
        let bodyRegion: String
        let captureDate: Date
        let notes: String
        let pitch: Double
        let roll: Double
        let yaw: Double
        let barometricPressure: Double?
        let altitude: Double?
        let filename: String // Reference to overview image file in package
        let locationMarkers: [LocationMarkerData]
    }
    
    struct LocationMarkerData: Codable {
        let id: String
        let moleID: String
        let x: Double
        let y: Double
    }
    
    /// Create a sync package from moles, images, and overviews
    static func create(moles: [MoleExportData], images: [ImageExportData], overviews: [OverviewExportData], sinceDate: Date) -> SyncPackage {
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
        
        let overviewData = overviews.map { overview in
            OverviewData(
                id: overview.id,
                bodyRegion: overview.bodyRegion,
                captureDate: overview.captureDate,
                notes: overview.notes,
                pitch: overview.pitch,
                roll: overview.roll,
                yaw: overview.yaw,
                barometricPressure: overview.barometricPressure,
                altitude: overview.altitude,
                filename: overview.filename,
                locationMarkers: overview.locationMarkers.map { marker in
                    LocationMarkerData(
                        id: marker.id,
                        moleID: marker.moleID,
                        x: marker.x,
                        y: marker.y
                    )
                }
            )
        }
        
        return SyncPackage(
            version: 1,
            exportDate: Date(),
            sinceDate: sinceDate,
            moles: moleData,
            images: imageData,
            overviews: overviewData
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

/// Temporary structure for exporting overview data
struct OverviewExportData {
    let id: String
    let bodyRegion: String
    let captureDate: Date
    let notes: String
    let pitch: Double
    let roll: Double
    let yaw: Double
    let barometricPressure: Double?
    let altitude: Double?
    let filename: String
    let locationMarkers: [LocationMarkerExportData]
}

/// Temporary structure for exporting location marker data
struct LocationMarkerExportData {
    let id: String
    let moleID: String
    let x: Double
    let y: Double
}