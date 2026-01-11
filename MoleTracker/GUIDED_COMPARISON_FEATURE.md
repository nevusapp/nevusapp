# Guided Comparison Feature

## Overview
The Guided Comparison feature provides a systematic way to compare the latest image of each mole with its reference image, allowing users to update notes during the review process.

## Implementation Date
January 11, 2026

## Components

### 1. GuidedComparisonService.swift
- **Location**: `Services/GuidedComparisonService.swift`
- **Purpose**: Manages the guided comparison workflow state
- **Key Features**:
  - Tracks comparison progress (compared, skipped, remaining)
  - Filters moles to only include those with at least 2 images
  - Sorts moles by last modified date (oldest first)
  - Provides navigation between moles (next, previous)
  - Maintains session state

### 2. GuidedComparisonView.swift
- **Location**: `Views/GuidedComparisonView.swift`
- **Purpose**: User interface for guided comparison
- **Key Features**:
  - Progress header showing completion percentage
  - Embedded ComparisonView for side-by-side or overlay comparison
  - Inline notes editing capability
  - Action buttons: "Verglichen" (Compared), "Überspringen" (Skip), "Zurück" (Back)
  - Completion summary with statistics
  - Instructions for users

### 3. ContentView Integration
- **Location**: `Views/ContentView.swift`
- **Changes**: Added "Geführter Vergleich" menu item
- **Icon**: `arrow.left.and.right.square`

## User Flow

1. **Start**: User selects "Geführter Vergleich" from the menu
2. **Filter**: System filters moles with at least 2 images
3. **Sort**: Moles are sorted by last modified date (oldest first)
4. **Review Loop**: For each mole:
   - Display mole information (region, side, image count)
   - Show comparison view with reference image vs. latest image
   - Display current notes with edit capability
   - User can:
     - Edit and save notes
     - Mark as compared (moves to next)
     - Skip (moves to next)
     - Go back to previous mole
5. **Complete**: Show summary with statistics

## Comparison Features

### Embedded ComparisonView
- **Side-by-Side Mode**: View images next to each other
- **Overlay Mode**: Slider to compare overlaid images
- **Zoom & Pan**: Pinch to zoom, drag to pan
- **Image Info**: Shows capture dates and time difference

### Notes Editing
- **Inline Editing**: Edit notes directly in the comparison view
- **Auto-save**: Notes are saved when marking as compared
- **Cancel Option**: Discard changes when skipping or going back

## Localization

All strings are localized in `Localizable.xcstrings`:
- `Geführter Vergleich` - Guided Comparison
- `Vergleich abgeschlossen!` - Comparison completed!
- `Verglichen` - Compared
- `%lld Leberflecke verglichen` - X moles compared
- `%lld von %lld verglichen` - X of Y compared
- `Bildvergleich` - Image comparison
- `Nicht genügend Bilder für Vergleich` - Not enough images for comparison
- `Mindestens 2 Bilder erforderlich` - At least 2 images required
- And more...

## Technical Details

### Filtering Logic
```swift
let comparableMoles = moles.filter { $0.imageCount >= 2 }
```
Only moles with at least 2 images (reference + latest) are included.

### Image Selection
- **Reference Image**: Uses `mole.referenceImage` (oldest or user-selected)
- **Latest Image**: Uses `mole.latestImage` (most recent)

### Progress Tracking
- **Compared**: Moles marked as reviewed
- **Skipped**: Moles skipped during review
- **Remaining**: Total - Compared - Skipped

### State Management
- Uses `@StateObject` for service lifecycle
- Uses `@State` for view-local state (notes editing, sheets)
- Integrates with SwiftData for persistence

## Benefits

1. **Systematic Review**: Ensures all moles are reviewed in order
2. **Efficient Workflow**: Streamlined process for comparing images
3. **Notes Integration**: Update observations during comparison
4. **Progress Tracking**: Visual feedback on completion status
5. **Flexible Navigation**: Can go back to review previous moles
6. **Skip Option**: Can skip moles that don't need review

## Usage Tips

1. **Best Practice**: Review moles regularly (e.g., monthly)
2. **Notes**: Document any changes or observations
3. **Skip Wisely**: Only skip if no changes are visible
4. **Complete Session**: Try to complete the full review in one session
5. **Reference Images**: Ensure reference images are properly set

## Future Enhancements

Potential improvements:
- Filter by date range (e.g., only moles not reviewed in X days)
- Export comparison report
- Add comparison annotations
- AI-assisted change detection
- Reminder notifications for regular reviews