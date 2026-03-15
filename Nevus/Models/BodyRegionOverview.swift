//
//  BodyRegionOverview.swift
//  Nevus
//
//  Created on 11.01.2026.
//

import Foundation
import SwiftData
import UIKit

@Model
final class BodyRegionOverview {
    @Attribute(.unique) var id: UUID
    var bodyRegion: String
    var captureDate: Date
    var notes: String
    
    @Attribute(.externalStorage)
    var imageData: Data?
    
    // Sensor data
    var pitch: Double
    var roll: Double
    var yaw: Double
    var barometricPressure: Double?
    var altitude: Double?
    
    // Location markers for moles on this overview image
    @Relationship(deleteRule: .cascade)
    var locationMarkers: [MoleLocationMarker]
    
    init(bodyRegion: String, image: UIImage) {
        self.id = UUID()
        self.bodyRegion = bodyRegion
        self.captureDate = Date()
        self.notes = ""
        self.imageData = image.jpegData(compressionQuality: 0.8)
        
        // Initialize sensor data with defaults
        self.pitch = 0
        self.roll = 0
        self.yaw = 0
        self.barometricPressure = nil
        self.altitude = nil
        self.locationMarkers = []
    }
    
    var uiImage: UIImage? {
        guard let data = imageData else { return nil }
        return UIImage(data: data)
    }
    
    var thumbnailImage: UIImage? {
        guard let image = uiImage else { return nil }
        let targetSize = CGSize(width: 200, height: 200)
        return image.preparingThumbnail(of: targetSize)
    }
    
    func updateSensorData(pitch: Double, roll: Double, yaw: Double, pressure: Double?, altitude: Double?) {
        self.pitch = pitch
        self.roll = roll
        self.yaw = yaw
        self.barometricPressure = pressure
        self.altitude = altitude
    }
}