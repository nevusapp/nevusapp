//
//  MoleImage.swift
//  MoleTracker
//
//  Created on 06.01.2026.
//

import Foundation
import SwiftData
import UIKit

@Model
final class MoleImage {
    @Attribute(.unique) var id: UUID
    var captureDate: Date
    
    // Store image data externally for better performance
    @Attribute(.externalStorage) var imageData: Data
    var thumbnailData: Data
    
    // Image dimensions
    var imageWidth: Int
    var imageHeight: Int
    
    // Sensor data (for future use)
    var pitch: Double
    var roll: Double
    var yaw: Double
    var barometricPressure: Double?
    var altitude: Double?
    
    // Relationship
    var mole: Mole?
    
    init(imageData: Data, thumbnailData: Data, width: Int, height: Int) {
        self.id = UUID()
        self.captureDate = Date()
        self.imageData = imageData
        self.thumbnailData = thumbnailData
        self.imageWidth = width
        self.imageHeight = height
        self.pitch = 0
        self.roll = 0
        self.yaw = 0
    }
    
    // Convenience initializer from UIImage (synchronous - use for immediate creation)
    convenience init?(image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            return nil
        }
        
        // Create thumbnail with better performance
        let thumbnailSize = CGSize(width: 200, height: 200)
        let thumbnail = image.preparingThumbnail(of: thumbnailSize) ?? image
        
        guard let thumbnailData = thumbnail.jpegData(compressionQuality: 0.7) else {
            return nil
        }
        
        self.init(
            imageData: imageData,
            thumbnailData: thumbnailData,
            width: Int(image.size.width),
            height: Int(image.size.height)
        )
    }
    
    // Async factory method for better performance
    @MainActor
    static func create(from image: UIImage) async -> MoleImage? {
        // Perform heavy operations off main thread
        let result: (imageData: Data, thumbnailData: Data, width: Int, height: Int)? = await Task.detached(priority: .userInitiated) {
            guard let imageData = image.jpegData(compressionQuality: 0.9) else {
                return nil as (imageData: Data, thumbnailData: Data, width: Int, height: Int)?
            }
            
            let thumbnailSize = CGSize(width: 200, height: 200)
            let thumbnail = image.preparingThumbnail(of: thumbnailSize) ?? image
            
            guard let thumbnailData = thumbnail.jpegData(compressionQuality: 0.7) else {
                return nil as (imageData: Data, thumbnailData: Data, width: Int, height: Int)?
            }
            
            return (
                imageData: imageData,
                thumbnailData: thumbnailData,
                width: Int(image.size.width),
                height: Int(image.size.height)
            )
        }.value
        
        guard let result = result else {
            return nil
        }
        
        return MoleImage(
            imageData: result.imageData,
            thumbnailData: result.thumbnailData,
            width: result.width,
            height: result.height
        )
    }
    
    var uiImage: UIImage? {
        UIImage(data: imageData)
    }
    
    var thumbnailImage: UIImage? {
        UIImage(data: thumbnailData)
    }
}