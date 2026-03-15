# Automatic Sync File Deletion Feature

## Overview

This feature automatically deletes `.moletracker` sync files from the Files app after successful import, eliminating the need for manual cleanup.

## Implementation Date
March 15, 2026

## Problem Solved

Previously, when users received a sync package via AirDrop:
1. File was saved to Files app
2. User opened it in MoleTracker
3. Data was imported successfully
4. **File remained in Files app** requiring manual deletion

This created clutter and potential confusion about whether files had been imported.

## Solution

The app now automatically deletes the original sync file from the Files app after successful import, while maintaining data safety through a temporary copy during the import process.

## Technical Implementation

### Files Modified

1. **`Models/ImportState.swift`**
   - Added `originalFileURL: URL?` to track the original file location
   - Added `importSucceeded: Bool` to track import success
   - Updated `reset()` to clear both new properties

2. **`MoleTracker/MoleTrackerApp.swift`**
   - Modified `handleIncomingURL()` to store original file URL
   - Updated `handleSheetDismiss()` to delete original file after successful import
   - Added `deleteOriginalFile()` function with security-scoped resource handling

3. **`Views/ImportConfirmationView.swift`**
   - Added `@EnvironmentObject private var importState: ImportState`
   - Modified `performImport()` to set `importState.importSucceeded = true` on success
   - Environment object passed from MoleTrackerApp

### How It Works

#### 1. File Reception (AirDrop)
```swift
// User receives file via AirDrop
// iOS calls onOpenURL with the file URL
```

#### 2. File Handling
```swift
handleIncomingURL(url)
├── Access security-scoped resource
├── Copy file to temp directory (for safe import)
├── Store original URL in importState.originalFileURL
└── Open import confirmation dialog
```

#### 3. Import Process
```swift
ImportConfirmationView.performImport()
├── Import data from temp file
├── On success: Set importState.importSucceeded = true
└── User dismisses dialog
```

#### 4. Cleanup
```swift
handleSheetDismiss()
├── Delete temp file (always)
├── If import succeeded:
│   └── Delete original file from Files app
└── Reset import state
```

### Security-Scoped Resource Access

The original file requires security-scoped resource access for deletion:

```swift
private func deleteOriginalFile(_ url: URL) {
    guard url.startAccessingSecurityScopedResource() else {
        print("⚠️ Could not access original file for deletion")
        return
    }
    
    defer {
        url.stopAccessingSecurityScopedResource()
    }
    
    try FileManager.default.removeItem(at: url)
}
```

## User Experience

### Before
1. Receive file via AirDrop
2. Tap "Open in MoleTracker"
3. Review and import data
4. **Manually navigate to Files app**
5. **Find and delete the sync file**

### After
1. Receive file via AirDrop
2. Tap "Open in MoleTracker"
3. Review and import data
4. ✅ **File automatically deleted** - Done!

## Safety Features

### Data Protection
- **Temp Copy**: Original file is copied to temp directory before import
- **Import First**: Data is fully imported before any deletion occurs
- **Success Check**: Original file only deleted if import succeeds
- **Error Handling**: If deletion fails, user can still manually delete

### Failure Scenarios

| Scenario | Behavior |
|----------|----------|
| Import fails | Original file kept, temp file deleted |
| Import cancelled | Original file kept, temp file deleted |
| Deletion fails | Console warning, user can manually delete |
| Permission denied | Console warning, file remains accessible |

## Console Logging

### Successful Flow
```
📥 Received URL: file:///...
✅ File copied to: file:///tmp/...
🎭 Creating ImportConfirmationView with URL: ...
📦 Loading package info from: ...
✅ Package info loaded successfully
✅ Import completed
📋 Sheet dismissed
🗑️ Cleaned up temp file
✅ Deleted original sync file from Files app: MoleSync_since_2026-03-15.moletracker
```

### Import Cancelled
```
📥 Received URL: file:///...
✅ File copied to: file:///tmp/...
📋 Sheet dismissed
🗑️ Cleaned up temp file
(Original file kept - import not completed)
```

### Deletion Failed
```
📋 Sheet dismissed
🗑️ Cleaned up temp file
⚠️ Failed to delete original file: [error details]
   User can manually delete: MoleSync_since_2026-03-15.moletracker
```

## Testing Checklist

- [ ] Receive sync file via AirDrop
- [ ] Open in MoleTracker
- [ ] Complete import successfully
- [ ] Verify original file deleted from Files app
- [ ] Verify data imported correctly
- [ ] Test import cancellation (file should remain)
- [ ] Test import failure (file should remain)
- [ ] Test with file in different locations
- [ ] Test manual import (should also auto-delete)
- [ ] Check console logs for proper cleanup

## Edge Cases Handled

1. **User cancels import**: Original file kept
2. **Import fails**: Original file kept
3. **Permission denied**: Graceful failure with console warning
4. **File already deleted**: No error, continues normally
5. **Multiple imports**: Each tracked independently

## Privacy & Security

- **No Cloud Storage**: Files never leave the device
- **Secure Deletion**: Uses iOS FileManager for proper deletion
- **Access Control**: Respects iOS security-scoped resources
- **User Control**: Import must be confirmed before deletion

## Future Enhancements

Potential improvements for future versions:

1. **User Preference**: Option to keep files after import
2. **Deletion Confirmation**: Optional prompt before deletion
3. **Trash/Undo**: Move to Recently Deleted instead of permanent deletion
4. **Batch Import**: Handle multiple files with single cleanup
5. **Statistics**: Track cleanup success rate

## Compatibility

- **iOS Version**: iOS 17.0+
- **File Types**: `.moletracker` files only
- **Transfer Methods**: 
  - ✅ AirDrop (automatic)
  - ✅ Manual import from Files app
  - ✅ Share sheet
  - ✅ Open in... menu

## Related Documentation

- [AIRDROP_SYNC_IMPLEMENTATION_COMPLETE.md](AIRDROP_SYNC_IMPLEMENTATION_COMPLETE.md) - Original sync feature
- [AIRDROP_SYNC_FIXES.md](AIRDROP_SYNC_FIXES.md) - File access fixes
- [AIRDROP_SYNC_SETUP.md](AIRDROP_SYNC_SETUP.md) - Setup instructions

## Summary

This enhancement improves the user experience by automating the cleanup of sync files after successful import. The implementation is safe, respects iOS security boundaries, and provides appropriate fallbacks for edge cases.

**Key Benefits:**
- ✅ No manual file cleanup required
- ✅ Automatic deletion after successful import
- ✅ Safe: Original file kept if import fails
- ✅ Transparent: Console logging for debugging
- ✅ Graceful: Handles permission errors appropriately

---

**Status**: ✅ Implemented and Ready for Testing
**Version**: 1.0