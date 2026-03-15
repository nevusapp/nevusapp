# Monthly Reminder Feature

## Overview
The Monthly Reminder feature automatically sends daily notifications to users one month after their last guided scan, encouraging them to perform regular mole monitoring.

## Implementation Date
January 11, 2026

## Features

### 1. Automatic Tracking
- The app automatically records the date when a guided scan is completed
- Date is stored in UserDefaults for persistence across app launches
- No user action required to enable tracking

### 2. Smart Notification Scheduling
- Notifications are scheduled to start exactly one month after the last guided scan
- Daily reminders are sent at 10:00 AM local time
- Up to 30 days of notifications are pre-scheduled
- Notifications automatically reschedule when a new guided scan is completed

### 3. Permission Management
- App requests notification permission on first launch
- Permission status is tracked and can be checked at any time
- Graceful handling if permission is denied

## Technical Implementation

### Components

#### NotificationService.swift
Main service managing all notification functionality:
- **Singleton pattern**: `NotificationService.shared`
- **Permission management**: Request and check notification authorization
- **Date tracking**: Store and retrieve last guided scan date
- **Scheduling logic**: Calculate and schedule notifications
- **Cancellation**: Remove all pending notifications when needed

Key Methods:
```swift
// Request notification permission
func requestNotificationPermission() async -> Bool

// Record completion of guided scan
func recordGuidedScanCompletion()

// Get last scan date
func getLastGuidedScanDate() -> Date?

// Check if reminders should be shown
func shouldShowReminder() -> Bool

// Cancel all notifications
func cancelAllNotifications()
```

#### GuidedScanningService.swift
Updated to record scan completion:
- Calls `NotificationService.shared.recordGuidedScanCompletion()` when scan finishes
- Automatically triggers notification scheduling

#### NevusApp.swift
Updated to request permissions:
- Requests notification permission on app launch using `.task` modifier
- Initializes NotificationService as StateObject

### Data Storage
- **Key**: `lastGuidedScanDate`
- **Storage**: UserDefaults
- **Type**: Date object
- **Persistence**: Survives app restarts and updates

### Notification Details
- **Title** (German): "Zeit für einen neuen Scan"
- **Title** (English): "Time for a New Scan"
- **Body** (German): "Es ist ein Monat seit Ihrem letzten geführten Scan vergangen. Führen Sie jetzt einen neuen Scan durch, um Ihre Leberflecke zu überwachen."
- **Body** (English): "It's been a month since your last guided scan. Perform a new scan now to monitor your moles."
- **Sound**: Default system sound
- **Badge**: Shows badge count of 1

### Scheduling Logic

1. **On Guided Scan Completion**:
   - Current date is saved to UserDefaults
   - All existing notifications are cancelled
   - New notifications are scheduled

2. **Notification Timing**:
   - Start date: Exactly 1 month after last scan
   - Time: 10:00 AM local time
   - Frequency: Daily
   - Duration: 30 days of pre-scheduled notifications

3. **Edge Cases**:
   - If already past the 1-month mark: Schedule immediate notification (5 seconds) plus ongoing daily reminders
   - If no scan recorded: No notifications scheduled
   - If permission denied: Notifications not scheduled but tracking continues

## User Experience

### First Time User
1. Opens app for first time
2. System prompts for notification permission
3. User grants or denies permission
4. Completes first guided scan
5. System records completion date
6. Notifications scheduled for 1 month later

### Returning User
1. Completes guided scan
2. System automatically updates last scan date
3. Previous notifications cancelled
4. New notifications scheduled for 1 month later
5. User receives daily reminders starting 1 month after scan

### Notification Interaction
1. User receives notification at 10:00 AM
2. Tapping notification opens the app
3. User can start a new guided scan
4. Completing scan resets the reminder cycle

## Localization

The feature is fully localized in:
- **German (de)**: Primary language
- **English (en)**: Secondary language

Localization keys:
- `notification_reminder_title`: Notification title
- `notification_reminder_body`: Notification body text

## Testing

### Manual Testing Steps

1. **Test Permission Request**:
   - Delete app and reinstall
   - Launch app
   - Verify permission prompt appears
   - Grant permission

2. **Test Scan Completion Recording**:
   - Complete a guided scan
   - Check UserDefaults for `lastGuidedScanDate`
   - Verify date is current

3. **Test Notification Scheduling**:
   - Complete a guided scan
   - Use `getPendingNotificationCount()` to verify notifications scheduled
   - Should see 30 pending notifications

4. **Test Notification Delivery** (Quick Test):
   - Modify `scheduleImmediateReminder()` to use 5-second delay
   - Complete a guided scan with past date (modify code temporarily)
   - Wait 5 seconds
   - Verify notification appears

5. **Test Notification Rescheduling**:
   - Complete first guided scan
   - Note pending notification count
   - Complete second guided scan
   - Verify old notifications cancelled and new ones scheduled

### Debug Methods

```swift
// Get count of pending notifications
let count = await NotificationService.shared.getPendingNotificationCount()
print("Pending notifications: \(count)")

// Get last scan date
if let date = NotificationService.shared.getLastGuidedScanDate() {
    print("Last scan: \(date)")
}

// Check if reminder should show
let shouldShow = NotificationService.shared.shouldShowReminder()
print("Should show reminder: \(shouldShow)")

// Get days since last scan
if let days = NotificationService.shared.daysSinceLastScan() {
    print("Days since last scan: \(days)")
}
```

## Future Enhancements

Potential improvements for future versions:

1. **Customizable Reminder Time**:
   - Allow users to set preferred notification time
   - Settings screen for notification preferences

2. **Reminder Frequency Options**:
   - Weekly, bi-weekly, or monthly options
   - Custom interval selection

3. **Snooze Functionality**:
   - "Remind me tomorrow" option
   - "Remind me in 3 days" option

4. **Statistics Integration**:
   - Show scan frequency in app
   - Display last scan date in UI
   - Reminder countdown timer

5. **Rich Notifications**:
   - Add action buttons ("Start Scan", "Remind Later")
   - Include scan statistics in notification

6. **Smart Scheduling**:
   - Learn user's preferred scan times
   - Adjust notification timing based on user behavior

## Troubleshooting

### Notifications Not Appearing

1. **Check Permission**:
   ```swift
   let settings = await UNUserNotificationCenter.current().notificationSettings()
   print("Authorization status: \(settings.authorizationStatus)")
   ```

2. **Check Pending Notifications**:
   ```swift
   let count = await NotificationService.shared.getPendingNotificationCount()
   print("Pending: \(count)")
   ```

3. **Check Last Scan Date**:
   ```swift
   if let date = NotificationService.shared.getLastGuidedScanDate() {
       print("Last scan: \(date)")
   } else {
       print("No scan recorded")
   }
   ```

4. **Verify System Settings**:
   - Open iOS Settings > Notifications > Nevus
   - Ensure notifications are enabled
   - Check that "Allow Notifications" is ON

### Notifications Scheduled But Not Delivered

- iOS may delay or batch notifications to save battery
- Notifications may be suppressed during Focus modes
- Check Do Not Disturb settings
- Verify device is not in Low Power Mode

### Reset Notification State

```swift
// Cancel all notifications and reset
NotificationService.shared.cancelAllNotifications()
UserDefaults.standard.removeObject(forKey: "lastGuidedScanDate")
```

## Privacy & Data

- **Data Stored**: Only the date of last guided scan
- **Location**: Local device (UserDefaults)
- **Sharing**: No data shared with external services
- **Deletion**: Data removed when app is deleted
- **User Control**: Users can disable notifications in iOS Settings

## Compliance

- **iOS Guidelines**: Follows Apple's notification best practices
- **User Consent**: Explicit permission requested before scheduling
- **Frequency**: Reasonable daily frequency (once per day)
- **Value**: Notifications provide clear health monitoring value

## Files Modified/Created

### New Files
- `Nevus/Services/NotificationService.swift`
- `Nevus/MONTHLY_REMINDER_FEATURE.md` (this file)

### Modified Files
- `Nevus/Services/GuidedScanningService.swift`
- `Nevus/Nevus/NevusApp.swift`
- `Nevus/Nevus/Localizable.xcstrings`
- `Nevus/Nevus.xcodeproj/project.pbxproj`

## Summary

The Monthly Reminder feature provides a seamless, automatic way to encourage users to maintain regular mole monitoring habits. By scheduling notifications one month after each guided scan, the app helps users stay on top of their skin health without requiring manual reminder setup.

The implementation is robust, handles edge cases gracefully, and respects user preferences and system settings. The feature is fully localized and ready for production use.