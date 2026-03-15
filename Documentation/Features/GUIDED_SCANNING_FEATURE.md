# Guided Scanning Feature

## Overview
The Guided Scanning feature provides a systematic workflow for photographing all moles in sequence, with progress tracking and navigation controls.

## Implementation Date
January 11, 2026

## Components

### 1. GuidedScanningService.swift
**Location:** `Nevus/Services/GuidedScanningService.swift`

**Purpose:** Manages the state and logic for the guided scanning workflow.

**Key Features:**
- Tracks current mole being scanned
- Maintains sets of scanned and skipped moles
- Calculates progress percentage
- Provides navigation methods (next, previous, skip)
- Sorts moles by last modified date (oldest first)

**Main Properties:**
- `isScanning`: Boolean indicating if scanning session is active
- `currentMoleIndex`: Index of current mole in sequence
- `scannedMoles`: Set of UUIDs for completed moles
- `skippedMoles`: Set of UUIDs for skipped moles
- `molesToScan`: Array of moles to scan in order

**Main Methods:**
- `startScanning(moles:)`: Initialize scanning session
- `markCurrentAsScanned()`: Mark current mole as done and advance
- `skipCurrent()`: Skip current mole and advance
- `goToPrevious()`: Navigate back to previous mole
- `finishScanning()`: Complete the session
- `cancelScanning()`: Abort the session

### 2. GuidedScanningView.swift
**Location:** `Nevus/Views/GuidedScanningView.swift`

**Purpose:** Provides the user interface for guided scanning workflow.

**Key Features:**
- Progress bar showing completion percentage
- Current mole information display
- Latest photo preview with reference image support
- Step-by-step instructions
- Camera integration with overlay support
- Navigation controls (take photo, skip, back)
- Completion summary with statistics

**UI Components:**
- **Progress Header**: Shows progress bar and count (X of Y scanned)
- **Mole Info Card**: Displays region, side, latest photo, and image count
- **Instructions Panel**: Three-step guide for taking photos
- **Action Buttons**: Take Photo, Skip, Back (conditional)
- **Completion View**: Success message with statistics
- **Summary Sheet**: Detailed breakdown of scanned/skipped moles

### 3. ContentView Integration
**Location:** `Nevus/Views/ContentView.swift`

**Changes:**
- Added `@State private var showingGuidedScanning = false`
- Added menu item "Geführtes Scannen" in toolbar menu
- Added sheet presentation for `GuidedScanningView`
- Menu item only visible when moles exist

## User Workflow

1. **Start Scanning**
   - User taps menu button (ellipsis) in ContentView
   - Selects "Geführtes Scannen" option
   - GuidedScanningView opens with first mole

2. **Scan Each Mole**
   - View shows current mole information
   - User sees latest photo as reference
   - Instructions guide the process
   - User taps "Foto aufnehmen" to open camera
   - Camera shows overlay of reference image for alignment
   - Photo is captured and automatically saved
   - Progress advances to next mole

3. **Navigation Options**
   - **Skip**: Move to next mole without taking photo
   - **Back**: Return to previous mole (if not first)
   - **Cancel**: Abort entire session (with confirmation)

4. **Completion**
   - After all moles processed, completion screen shows
   - Statistics displayed (scanned count, skipped count)
   - "Zusammenfassung anzeigen" button shows detailed summary
   - "Fertig" button closes the view

## Localization

All UI strings are localized in `Localizable.xcstrings` with German (de) and English (en) translations:

### Key Localization Strings
- `guided_scanning_title`: "Geführtes Scannen" / "Guided Scanning"
- `guided_scanning_progress`: "%1$lld von %2$lld gescannt" / "%1$lld of %2$lld scanned"
- `guided_scanning_take_photo`: "Foto aufnehmen" / "Take Photo"
- `guided_scanning_skip`: "Überspringen" / "Skip"
- `guided_scanning_back`: "Zurück" / "Back"
- `guided_scanning_complete_title`: "Scannen abgeschlossen!" / "Scanning Complete!"
- And many more...

## Technical Details

### State Management
- Uses `@StateObject` for `GuidedScanningService` instance
- Service is `@MainActor` isolated for UI updates
- Progress tracking uses `@Published` properties

### Image Processing
- Integrates with existing `CameraView` component
- Uses reference image overlay for alignment
- Asynchronous image creation with `MoleImage.create(from:)`
- Shows processing indicator during image save

### Data Persistence
- Images automatically saved to SwiftData context
- Mole's `lastModified` date updated on new image
- No manual save required - handled by SwiftData

### Navigation
- Uses SwiftUI sheets for modal presentation
- Confirmation alert for cancellation
- Automatic dismissal on completion

## Benefits

1. **Systematic Approach**: Ensures all moles are photographed in sequence
2. **Progress Tracking**: Visual feedback on completion status
3. **Consistency**: Reference image overlay helps maintain consistent angles
4. **Flexibility**: Skip option for inaccessible moles
5. **Error Recovery**: Back button allows correction of mistakes
6. **Statistics**: Summary provides overview of session results

## Future Enhancements

Potential improvements for future versions:
- Filter options (by region, by date since last photo)
- Reminder notifications for regular scanning
- Export guided scanning session report
- Custom scanning order preferences
- Voice guidance for hands-free operation
- Integration with health tracking apps

## Testing Checklist

- [x] Service correctly tracks scanning state
- [x] Progress bar updates accurately
- [x] Camera integration works with overlay
- [x] Images save correctly to moles
- [x] Navigation (next, skip, back) functions properly
- [x] Completion view shows correct statistics
- [x] Cancellation confirmation works
- [x] Localization strings display correctly
- [x] Files added to Xcode project
- [x] No compilation errors

## Files Modified/Created

### Created:
1. `Nevus/Services/GuidedScanningService.swift` (95 lines)
2. `Nevus/Views/GuidedScanningView.swift` (475 lines)
3. `Nevus/GUIDED_SCANNING_FEATURE.md` (this file)

### Modified:
1. `Nevus/Views/ContentView.swift`
   - Added state variable for guided scanning
   - Added menu item
   - Added sheet presentation

2. `Nevus/Nevus/Localizable.xcstrings`
   - Added 25+ localization strings for guided scanning

3. `Nevus/Nevus.xcodeproj/project.pbxproj`
   - Added new files to build system

## Conclusion

The Guided Scanning feature successfully implements a user-friendly workflow for systematically photographing all moles. The implementation follows SwiftUI best practices, integrates seamlessly with existing components, and provides a polished user experience with proper localization and progress tracking.