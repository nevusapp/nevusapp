# Mole Location on Overview Images Feature

## Overview
This feature allows users to link moles with overview images and mark their exact location on those images. Users can view the overview image with the mole's position highlighted, zoom in for detail, and manage multiple location links per mole.

## Implementation Date
January 11, 2026

## Components

### 1. Data Models

#### MoleLocationMarker.swift
- **Purpose**: Stores the relationship between a mole and an overview image with position data
- **Key Properties**:
  - `normalizedX`, `normalizedY`: Position coordinates (0.0 to 1.0) relative to image dimensions
  - `label`: Optional text label for the marker
  - `mole`: Reference to the linked Mole
  - `overviewImage`: Reference to the linked BodyRegionOverview

#### Updated Models
- **Mole.swift**: Added `locationMarkers` relationship array
- **BodyRegionOverview.swift**: Added `locationMarkers` relationship array

### 2. Views

#### MoleLocationView.swift
Main view for managing mole location links with the following sub-views:

##### MoleLocationView
- Lists all linked overview images for a mole
- Shows available overview images that can be linked
- Displays marker count badge
- Allows deletion of location links via swipe actions

##### MarkerPlacementView
- Interactive view for placing a marker on an overview image
- Tap gesture to select position
- Visual marker preview (red circle with white border)
- Optional label input field
- Saves normalized coordinates for resolution-independent positioning

##### OverviewWithMarkerView
- Displays overview image with mole marker highlighted
- Full zoom and pan gesture support (1x to 5x zoom)
- Marker scales inversely with zoom for consistent visibility
- Reset zoom button
- Displays marker label if present
- Shows zoom level percentage

##### Supporting Row Views
- **LinkedOverviewRow**: Shows linked overview with mini marker preview
- **AvailableOverviewRow**: Shows available overviews with link status

### 3. Integration

#### MoleDetailView.swift
Added new section "Location on Overview" with:
- Navigation link to MoleLocationView
- Badge showing number of linked locations
- Footer text explaining the feature

#### NevusApp.swift
- Registered `MoleLocationMarker` model with SwiftData container

#### Xcode Project
- Added new files to project.pbxproj:
  - `MoleLocationMarker.swift` in Models group
  - `MoleLocationView.swift` in Views group

### 4. Localization

Added German and English translations for:
- `location_title`: "Leberfleck-Position" / "Mole Location"
- `location_linked_overviews`: "Verknüpfte Übersichtsbilder" / "Linked Overview Images"
- `location_available_overviews`: "Verfügbare Übersichtsbilder" / "Available Overview Images"
- `location_empty_title`: "Keine Verknüpfungen" / "No Links"
- `location_empty_message`: Instructions for linking
- `marker_placement_title`: "Position markieren" / "Mark Location"
- `marker_placement_instruction`: "Tippen Sie auf die Position des Leberflecks" / "Tap on the mole's location"
- `marker_label_placeholder`: "Optionale Beschriftung" / "Optional label"
- `marker_save_action`: "Position speichern" / "Save Location"
- `location_overview_title`: "Übersichtsbild" / "Overview Image"
- `zoom_reset`: "Zurücksetzen" / "Reset"
- `zoom_level`: "Zoom: %lld%%" (both languages)
- `section_location_overview`: "Position auf Übersichtsbild" / "Location on Overview"
- And more...

## User Workflow

### Linking a Mole to an Overview Image

1. Open a mole's detail view
2. Tap on "Position auf Übersichtsbild" / "Location on Overview" section
3. Select an available overview image from the list
4. Tap on the exact position of the mole on the overview image
5. Optionally add a label (e.g., "links oben" / "upper left")
6. Tap "Position speichern" / "Save Location"

### Viewing a Linked Location

1. From MoleLocationView, tap on a linked overview image
2. The overview image opens with the mole's position marked by a red circle
3. Use pinch gesture to zoom (1x to 5x)
4. Use drag gesture to pan around the zoomed image
5. Tap "Zurücksetzen" / "Reset" to reset zoom and pan
6. Marker remains visible and scales appropriately with zoom level

### Managing Location Links

- **Delete a link**: Swipe left on a linked overview in MoleLocationView
- **View multiple links**: A mole can be linked to multiple overview images
- **Badge indicator**: The number of links is shown as a badge in MoleDetailView

## Technical Details

### Coordinate System
- Uses normalized coordinates (0.0 to 1.0) for resolution independence
- Coordinates are relative to image dimensions
- Conversion happens in MarkerPlacementView when saving
- Conversion back to screen coordinates happens in OverviewWithMarkerView

### Gesture Handling
- **Tap**: Place marker (MarkerPlacementView) or select item (list views)
- **Pinch**: Zoom in/out (1x to 5x range)
- **Drag**: Pan around zoomed image
- **Swipe**: Delete action on list items

### Data Relationships
```
Mole (1) ←→ (N) MoleLocationMarker (N) ←→ (1) BodyRegionOverview
```
- One mole can have multiple location markers
- One overview image can have multiple markers (from different moles)
- Cascade delete: Deleting a mole or overview deletes associated markers

### Visual Design
- **Marker**: Red circle (30pt diameter) with white border (3pt)
- **Marker on thumbnail**: Smaller (12pt) for preview in list
- **Shadow**: 5pt radius for depth
- **Inverse scaling**: Marker size adjusts with zoom for consistent visibility

## Benefits

1. **Context Documentation**: Shows where a mole is located on the body
2. **Multiple Perspectives**: Link to multiple overview images for different angles
3. **Zoom Capability**: Examine overview images in detail
4. **Easy Navigation**: Quick access from mole detail view
5. **Visual Feedback**: Clear marker indication on both thumbnails and full images
6. **Flexible**: Optional labels for additional context

## Future Enhancements

Potential improvements:
- Auto-suggest nearby moles when placing markers
- Show all moles on an overview image simultaneously
- Export overview images with markers
- Compare marker positions over time
- Measurement tools (distance between moles)
- AR-based marker placement using device camera

## Testing Checklist

- [x] Create MoleLocationMarker model
- [x] Update Mole and BodyRegionOverview models
- [x] Implement MoleLocationView with all sub-views
- [x] Add navigation from MoleDetailView
- [x] Implement marker placement with tap gesture
- [x] Implement zoom and pan gestures
- [x] Add localization strings (German and English)
- [x] Update Xcode project file
- [x] Register model with SwiftData container

## Notes

- The feature requires at least one overview image in the mole's body region
- Markers are stored with normalized coordinates for resolution independence
- The zoom range is limited to 1x-5x to maintain usability
- Marker visibility is maintained across all zoom levels through inverse scaling