//
//  NotificationService.swift
//  Nevus
//
//  Created on 11.01.2026.
//

import Foundation
import UserNotifications
import SwiftData
import Combine

/// Service to manage notification scheduling for guided scan reminders
@MainActor
class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var notificationPermissionGranted = false
    
    private let notificationIdentifier = "guided_scan_reminder"
    private let userDefaultsKey = "lastGuidedScanDate"
    
    private init() {
        checkNotificationPermission()
    }
    
    /// Request notification permission from user
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            notificationPermissionGranted = granted
            return granted
        } catch {
            print("Error requesting notification permission: \(error)")
            return false
        }
    }
    
    /// Check current notification permission status
    func checkNotificationPermission() {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            notificationPermissionGranted = settings.authorizationStatus == .authorized
        }
    }
    
    /// Record that a guided scan was completed
    func recordGuidedScanCompletion() {
        let now = Date()
        UserDefaults.standard.set(now, forKey: userDefaultsKey)
        
        // Schedule notifications for one month from now
        scheduleMonthlyReminders()
    }
    
    /// Get the date of the last guided scan
    func getLastGuidedScanDate() -> Date? {
        return UserDefaults.standard.object(forKey: userDefaultsKey) as? Date
    }
    
    /// Schedule daily notifications starting one month after last scan
    private func scheduleMonthlyReminders() {
        // // FOR TESTING ONLY - REMOVE
        // scheduleImmediateReminder();
        // return;

        // Cancel any existing notifications
        cancelAllNotifications()
        
        guard notificationPermissionGranted else {
            print("Notification permission not granted")
            return
        }
        
        guard let lastScanDate = getLastGuidedScanDate() else {
            print("No last scan date found")
            return
        }
        
        // Calculate date one month from last scan
        let calendar = Calendar.current
        guard let reminderStartDate = calendar.date(byAdding: .month, value: 1, to: lastScanDate) else {
            print("Could not calculate reminder start date")
            return
        }
        
        // Only schedule if the reminder date is in the future
        guard reminderStartDate > Date() else {
            print("Reminder start date is in the past, scheduling for today")
            // If we're already past the reminder date, schedule for today
            scheduleImmediateReminder()
            return
        }
        
        // Schedule daily notifications starting from the reminder date
        // We'll schedule 30 days worth of notifications
        for dayOffset in 0..<30 {
            guard let notificationDate = calendar.date(byAdding: .day, value: dayOffset, to: reminderStartDate) else {
                continue
            }
            
            // Set notification time to 10:00 AM
            var components = calendar.dateComponents([.year, .month, .day], from: notificationDate)
            components.hour = 10
            components.minute = 0
            
            let content = UNMutableNotificationContent()
            content.title = String(localized: "notification_reminder_title")
            content.body = String(localized: "notification_reminder_body")
            content.sound = .default
            content.badge = 1
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: "\(notificationIdentifier)_\(dayOffset)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification for day \(dayOffset): \(error)")
                }
            }
        }
        
        print("Scheduled 30 daily reminders starting from \(reminderStartDate)")
    }
    
    /// Schedule an immediate reminder (for when we're past the one month mark)
    private func scheduleImmediateReminder() {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification_reminder_title")
        content.body = String(localized: "notification_reminder_body")
        content.sound = .default
        content.badge = 1
        
        // Schedule for 5 seconds from now (for immediate testing)
        // In production, you might want to schedule for the next 10 AM
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(notificationIdentifier)_immediate",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling immediate notification: \(error)")
            } else {
                print("Scheduled immediate reminder")
            }
        }
        
        // Also schedule daily reminders going forward
        scheduleOngoingDailyReminders()
    }
    
    /// Schedule ongoing daily reminders (when already past the one month mark)
    private func scheduleOngoingDailyReminders() {
        let calendar = Calendar.current
        
        // Schedule for the next 30 days at 10 AM
        for dayOffset in 1...30 {
            guard let notificationDate = calendar.date(byAdding: .day, value: dayOffset, to: Date()) else {
                continue
            }
            
            var components = calendar.dateComponents([.year, .month, .day], from: notificationDate)
            components.hour = 10
            components.minute = 0
            
            let content = UNMutableNotificationContent()
            content.title = String(localized: "notification_reminder_title")
            content.body = String(localized: "notification_reminder_body")
            content.sound = .default
            content.badge = 1
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: "\(notificationIdentifier)_ongoing_\(dayOffset)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling ongoing notification for day \(dayOffset): \(error)")
                }
            }
        }
    }
    
    /// Cancel all scheduled notifications
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        // Reset badge count
        UNUserNotificationCenter.current().setBadgeCount(0)
        print("Cancelled all notifications")
    }
    
    /// Get count of pending notifications (for debugging)
    func getPendingNotificationCount() async -> Int {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        return requests.count
    }
    
    /// Check if reminders should be shown (one month has passed since last scan)
    func shouldShowReminder() -> Bool {
        guard let lastScanDate = getLastGuidedScanDate() else {
            return false
        }
        
        let calendar = Calendar.current
        guard let oneMonthLater = calendar.date(byAdding: .month, value: 1, to: lastScanDate) else {
            return false
        }
        
        return Date() >= oneMonthLater
    }
    
    /// Get days since last scan
    func daysSinceLastScan() -> Int? {
        guard let lastScanDate = getLastGuidedScanDate() else {
            return nil
        }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: lastScanDate, to: Date())
        return components.day
    }
}