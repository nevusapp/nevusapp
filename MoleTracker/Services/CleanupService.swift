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
        
        var dateString: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static func == (lhs: RecordingSession, rhs: RecordingSession) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    /// Get all recording sessions grouped by calendar date
    /// Overview images are included in the count but NOT marked as deletable
    static func getRecordingSessions(from moles: [Mole], overviews: [BodyRegionOverview]) -> [RecordingSession] {
        var sessionDict: [Date: (total: Int, deletable: Int)] = [:]
        let calendar = Calendar.current
        
        // Process mole images
        for mole in moles {
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
                // All images except the last one (most recent) can be deleted
                let deletableCount = max(0, totalCount - 1)
                
                if let existing = sessionDict[date] {
                    sessionDict[date] = (
                        total: existing.total + totalCount,
                        deletable: existing.deletable + deletableCount
                    )
                } else {
                    sessionDict[date] = (total: totalCount, deletable: deletableCount)
                }
            }
        }
        
        // Process overview images (count them but don't mark as deletable)
        for overview in overviews {
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: overview.captureDate)
            if let normalizedDate = calendar.date(from: dateComponents) {
                if let existing = sessionDict[normalizedDate] {
                    sessionDict[normalizedDate] = (
                        total: existing.total + 1,
                        deletable: existing.deletable // Don't add to deletable count
                    )
                } else {
                    sessionDict[normalizedDate] = (total: 1, deletable: 0)
                }
            }
        }
        
        // Convert to array and sort by date (newest first)
        return sessionDict.map { date, counts in
            RecordingSession(
                date: date,
                photoCount: counts.total,
                deletablePhotoCount: counts.deletable
            )
        }.sorted { $0.date > $1.date }
    }
    
    /// Delete photos from selected sessions, keeping the last photo of each mole
    static func deletePhotosFromSessions(
        _ sessions: Set<RecordingSession>,
        moles: inout [Mole]
    ) -> (deletedCount: Int, freedSpace: Int64) {
        let calendar = Calendar.current
        let sessionDates = Set(sessions.map { $0.date })
        
        var deletedCount = 0
        var freedSpace: Int64 = 0
        
        for moleIndex in moles.indices {
            var mole = moles[moleIndex]
            
            // Group images by calendar date
            var imagesByDate: [Date: [MoleImage]] = [:]
            
            for image in mole.images {
                let dateComponents = calendar.dateComponents([.year, .month, .day], from: image.captureDate)
                if let normalizedDate = calendar.date(from: dateComponents) {
                    imagesByDate[normalizedDate, default: []].append(image)
                }
            }
            
            // Find images to delete
            var imagesToDelete: [MoleImage] = []
            
            for (date, images) in imagesByDate {
                if sessionDates.contains(date) {
                    // Sort images by timestamp (oldest first)
                    let sortedImages = images.sorted { $0.captureDate < $1.captureDate }
                    
                    // Mark all except the last one for deletion
                    imagesToDelete.append(contentsOf: sortedImages.dropLast())
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