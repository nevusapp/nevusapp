import Foundation
import SwiftUI

/// Service for managing photo cleanup operations
class CleanupService {
    
    /// Represents a recording session (date) with photo count
    struct RecordingSession: Identifiable, Hashable {
        let id = UUID()
        let date: Date
        var photoCount: Int
        var deletablePhotoCount: Int
        var totalStorageBytes: Int64
        var deletableStorageBytes: Int64
        
        var dateString: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
        
        var totalStorageString: String {
            formatBytes(totalStorageBytes)
        }
        
        var deletableStorageString: String {
            formatBytes(deletableStorageBytes)
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static func == (lhs: RecordingSession, rhs: RecordingSession) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    /// Get all recording sessions grouped by calendar date
    /// Overview images and reference images are included in the count but NOT marked as deletable
    static func getRecordingSessions(from moles: [Mole], overviews: [BodyRegionOverview]) -> [RecordingSession] {
        var sessionDict: [Date: (total: Int, deletable: Int, totalBytes: Int64, deletableBytes: Int64)] = [:]
        let calendar = Calendar.current
        
        // Process mole images
        for mole in moles {
            // Find the latest image overall (across all dates)
            let latestImage = mole.images.max(by: { $0.captureDate < $1.captureDate })
            
            // Get the reference image (explicitly set or defaults to oldest)
            let referenceImage = mole.referenceImage
            
            // Group images by calendar date
            var imagesByDate: [Date: [MoleImage]] = [:]
            
            for image in mole.images {
                let dateComponents = calendar.dateComponents([.year, .month, .day], from: image.captureDate)
                if let normalizedDate = calendar.date(from: dateComponents) {
                    imagesByDate[normalizedDate, default: []].append(image)
                }
            }
            
            // Count total and deletable images per date
            for (date, images) in imagesByDate {
                let totalCount = images.count
                let totalBytes = images.reduce(Int64(0)) { $0 + Int64($1.imageData.count) }
                
                // Determine which images are deletable
                let deletableImages = images.filter { image in
                    // Never delete the latest image overall
                    if let latest = latestImage, image.id == latest.id {
                        return false
                    }
                    
                    // Never delete the reference image
                    if let reference = referenceImage, image.id == reference.id {
                        return false
                    }
                    
                    return true
                }
                
                let deletableCount = deletableImages.count
                let deletableBytes = deletableImages.reduce(Int64(0)) { $0 + Int64($1.imageData.count) }
                
                if let existing = sessionDict[date] {
                    sessionDict[date] = (
                        total: existing.total + totalCount,
                        deletable: existing.deletable + deletableCount,
                        totalBytes: existing.totalBytes + totalBytes,
                        deletableBytes: existing.deletableBytes + deletableBytes
                    )
                } else {
                    sessionDict[date] = (total: totalCount, deletable: deletableCount, totalBytes: totalBytes, deletableBytes: deletableBytes)
                }
            }
        }
        
        // Process overview images (count them but don't mark as deletable)
        for overview in overviews {
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: overview.captureDate)
            if let normalizedDate = calendar.date(from: dateComponents) {
                let overviewBytes = Int64(overview.imageData?.count ?? 0)
                
                if let existing = sessionDict[normalizedDate] {
                    sessionDict[normalizedDate] = (
                        total: existing.total + 1,
                        deletable: existing.deletable, // Don't add to deletable count
                        totalBytes: existing.totalBytes + overviewBytes,
                        deletableBytes: existing.deletableBytes // Don't add to deletable bytes
                    )
                } else {
                    sessionDict[normalizedDate] = (total: 1, deletable: 0, totalBytes: overviewBytes, deletableBytes: 0)
                }
            }
        }
        
        // Convert to array and sort by date (newest first)
        return sessionDict.map { date, counts in
            RecordingSession(
                date: date,
                photoCount: counts.total,
                deletablePhotoCount: counts.deletable,
                totalStorageBytes: counts.totalBytes,
                deletableStorageBytes: counts.deletableBytes
            )
        }.sorted { $0.date > $1.date }
    }
    
    /// Delete photos from selected sessions, keeping the last photo of each mole and reference images
    static func deletePhotosFromSessions(
        _ sessions: Set<RecordingSession>,
        moles: inout [Mole]
    ) -> (deletedCount: Int, freedSpace: Int64) {
        let calendar = Calendar.current
        let sessionDates = Set(sessions.map { $0.date })
        
        var deletedCount = 0
        var freedSpace: Int64 = 0
        
        for moleIndex in moles.indices {
            let mole = moles[moleIndex]
            
            // Find the latest image overall (across all dates)
            let latestImage = mole.images.max(by: { $0.captureDate < $1.captureDate })
            
            // Get the reference image (explicitly set or defaults to oldest)
            let referenceImage = mole.referenceImage
            
            // Find images to delete
            var imagesToDelete: [MoleImage] = []
            
            for image in mole.images {
                // Get the calendar date for this image
                let dateComponents = calendar.dateComponents([.year, .month, .day], from: image.captureDate)
                guard let normalizedDate = calendar.date(from: dateComponents) else {
                    continue
                }
                
                // Only consider images from selected sessions
                if sessionDates.contains(normalizedDate) {
                    // Never delete the latest image overall
                    if let latest = latestImage, image.id == latest.id {
                        continue
                    }
                    
                    // Never delete the reference image
                    if let reference = referenceImage, image.id == reference.id {
                        continue
                    }
                    
                    // This image can be deleted
                    imagesToDelete.append(image)
                }
            }
            
            // Delete the marked images
            for imageToDelete in imagesToDelete {
                if let imageIndex = mole.images.firstIndex(where: { $0.id == imageToDelete.id }) {
                    // Calculate file size before deletion
                    freedSpace += Int64(imageToDelete.imageData.count)
                    
                    // Remove from array
                    mole.images.remove(at: imageIndex)
                    deletedCount += 1
                }
            }
            
            moles[moleIndex] = mole
        }
        
        return (deletedCount, freedSpace)
    }
    
    /// Format bytes to human-readable string
    static func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}