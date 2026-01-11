# Export Functionality Fix

## Problem
The export feature was failing with the error:
```
error fetching item for URL:file:///private/var/mobile/Containers/Data/Application/.../tmp/MoleExport_....zip
```

This occurred because the iOS Share Sheet couldn't access files in the temporary directory due to iOS sandboxing restrictions.

## Solution
Updated `ExportService.swift` to use the **Documents directory** instead of the temporary directory for creating ZIP files.

### Changes Made

#### 1. `exportMole()` method (Lines 15-60)
**Before:**
```swift
let tempDir = fileManager.temporaryDirectory
let exportDir = tempDir.appendingPathComponent("MoleExport_\(UUID().uuidString)")
// ...
let zipURL = tempDir.appendingPathComponent("MoleExport_\(mole.id.uuidString).zip")
```

**After:**
```swift
guard let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
    return nil
}
let exportDir = documentsDir.appendingPathComponent("MoleExport_\(UUID().uuidString)")
// ...
let zipURL = documentsDir.appendingPathComponent("MoleExport_\(mole.id.uuidString).zip")
```

#### 2. `exportAllMoles()` method (Lines 63-118)
**Before:**
```swift
let tempDir = fileManager.temporaryDirectory
let exportDir = tempDir.appendingPathComponent("AllMolesExport_\(UUID().uuidString)")
// ...
let zipURL = tempDir.appendingPathComponent("AllMoles_\(Date().formatted(date: .numeric, time: .omitted)).zip")
```

**After:**
```swift
guard let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
    return nil
}
let exportDir = documentsDir.appendingPathComponent("AllMolesExport_\(UUID().uuidString)")
// ...
let zipURL = documentsDir.appendingPathComponent("AllMoles_\(Date().formatted(date: .numeric, time: .omitted)).zip")
```

## Why This Works

### iOS Sandboxing
- **Temporary Directory**: iOS restricts access to the temporary directory for security reasons. The Share Sheet cannot access files stored there.
- **Documents Directory**: This is the proper location for user-generated content that should be accessible to the user and other apps through the Share Sheet.

### File Lifecycle
1. Create temporary working directory in Documents (e.g., `MoleExport_UUID`)
2. Export images and metadata to working directory
3. Create ZIP file in Documents directory
4. Clean up temporary working directory
5. Return ZIP URL to Share Sheet (now accessible)

## Testing
To verify the fix works:
1. Open a mole detail view
2. Tap the share button (top-right)
3. Select "Export Mole"
4. The Share Sheet should now successfully display sharing options
5. You can share via AirDrop, Messages, Mail, Files, etc.

## Additional Notes
- The temporary working directories are still cleaned up after ZIP creation
- ZIP files remain in Documents directory until shared/deleted
- iOS will automatically manage Documents directory storage
- Files are backed up to iCloud if enabled

## Date
Fixed: January 10, 2026