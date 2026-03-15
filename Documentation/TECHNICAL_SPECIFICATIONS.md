# Nevus - Technische Spezifikationen

**Letzte Aktualisierung:** 15. März 2026
**Version:** 1.0 (Implementiert)

## System-Anforderungen

### Minimum Requirements
- **iOS Version**: 17.6+ (SwiftData erforderlich)
- **Device**: iPhone 12 oder neuer, iPad (alle Modelle mit iOS 17.6+)
- **Storage**: 500 MB freier Speicher (minimal)
- **RAM**: 3 GB
- **Kamera**: Rückkamera erforderlich
- **Sensoren**: Keine Sensordaten aktuell implementiert

### Empfohlene Requirements
- **iOS Version**: 17.6+
- **Device**: iPhone 14 Pro oder neuer, iPad Pro
- **Storage**: 2 GB freier Speicher
- **iCloud**: Optional für automatisches Backup (SwiftData iCloud Sync)

## Datenmodell-Spezifikationen

### Mole Entity

| Feld | Typ | Beschreibung | Constraints |
|------|-----|--------------|-------------|
| `id` | UUID | Eindeutige Kennung | Primary Key, Unique |
| `createdAt` | Date | Erstellungsdatum | Not Null |
| `lastModified` | Date | Letzte Änderung | Not Null, Auto-update |
| `bodyRegion` | String | Körperregion | 12 Regionen (siehe BodyRegion Enum) |
| `bodySide` | String | Körperseite | Region-spezifische Seiten (siehe BodySide Enum) |
| `notes` | String | Benutzer-Notizen | Default: "" |
| `referenceImageID` | UUID? | Referenzbild für Overlay | Optional, default: ältestes Bild |

**Relationships:**
- `images`: One-to-Many zu MoleImage (Cascade Delete)
- `locationMarkers`: One-to-Many zu MoleLocationMarker (Cascade Delete)

**Implementierte Body Regions (12):**
- head, neck, armLeft, armRight, chest, abdomen, pelvis, backUpper, backMiddle, backLower, legLeft, legRight

**Body Sides (region-spezifisch):**
- Head: headTop, headFront, headLeft, headRight, headBack
- Neck: neckFront, neckLeft, neckRight, neckBack
- Torso: torsoLeft, torsoCenter, torsoRight
- Arms: armUpperFront, armUpperBack, armLowerInner, armLowerOuter, handInner, handOuter
- Legs: legThighFront, legThighBack, legThighInner, legThighOuter, legCalfFront, legCalfBack, legCalfInner, legCalfOuter, footTop, footSole

### MoleImage Entity

| Feld | Typ | Beschreibung | Constraints |
|------|-----|--------------|-------------|
| `id` | UUID | Eindeutige Kennung | Primary Key, Unique |
| `captureDate` | Date | Aufnahmedatum | Not Null |
| `imageData` | Data | Vollbild (JPEG) | External Storage, 90% Qualität |
| `thumbnailData` | Data | Thumbnail (JPEG) | 200x200, 70% Qualität |
| `imageWidth` | Int | Bildbreite in Pixel | Not Null |
| `imageHeight` | Int | Bildhöhe in Pixel | Not Null |

**Relationships:**
- `mole`: Many-to-One zu Mole

**Hinweis:** Sensordaten und ML-Features sind aktuell nicht implementiert.

### BodyRegionOverview Entity

| Feld | Typ | Beschreibung | Constraints |
|------|-----|--------------|-------------|
| `id` | UUID | Eindeutige Kennung | Primary Key, Unique |
| `bodyRegion` | String | Körperregion | Entspricht BodyRegion Enum |
| `imageData` | Data | Vollbild (JPEG) | External Storage |
| `thumbnailData` | Data | Thumbnail (JPEG) | 200x200 |
| `captureDate` | Date | Aufnahmedatum | Not Null |
| `notes` | String | Notizen zum Übersichtsbild | Default: "" |

**Hinweis:** Übersichtsbilder für gesamte Körperregionen, unabhängig von einzelnen Leberflecken.

### MoleLocationMarker Entity

| Feld | Typ | Beschreibung | Constraints |
|------|-----|--------------|-------------|
| `id` | UUID | Eindeutige Kennung | Primary Key, Unique |
| `x` | Double | X-Koordinate | 0.0 - 1.0 |
| `y` | Double | Y-Koordinate | 0.0 - 1.0 |

**Relationships:**
- `mole`: Many-to-One zu Mole
- `overviewImage`: Many-to-One zu BodyRegionOverview

**Hinweis:** Verknüpft Leberflecke mit Positionen auf Übersichtsbildern.

## Kamera-Spezifikationen

### Capture Settings

```swift
struct CameraConfiguration {
    // Photo Settings
    static let photoFormat = AVFileType.jpg
    static let photoQuality: CGFloat = 0.9
    static let maxResolution = CGSize(width: 4032, height: 3024) // 12 MP
    
    // Capture Settings
    static let flashMode: AVCaptureDevice.FlashMode = .auto
    static let focusMode: AVCaptureDevice.FocusMode = .continuousAutoFocus
    static let exposureMode: AVCaptureDevice.ExposureMode = .continuousAutoExposure
    static let whiteBalanceMode: AVCaptureDevice.WhiteBalanceMode = .continuousAutoWhiteBalance
    
    // Stabilization
    static let videoStabilization: AVCaptureVideoStabilizationMode = .auto
    
    // HDR
    static let isHDREnabled = true
}
```

### Thumbnail Generation

```swift
struct ThumbnailConfiguration {
    static let size = CGSize(width: 200, height: 200)
    static let compressionQuality: CGFloat = 0.7
    static let contentMode: UIView.ContentMode = .scaleAspectFill
}
```

## Sensor-Spezifikationen

### CoreMotion Configuration

```swift
struct SensorConfiguration {
    // Update Intervals
    static let motionUpdateInterval: TimeInterval = 0.1 // 10 Hz
    static let altimeterUpdateInterval: TimeInterval = 1.0 // 1 Hz
    
    // Thresholds
    static let stabilityThreshold: Double = 0.05 // Radians
    static let minimumStabilityDuration: TimeInterval = 0.5 // Seconds
    
    // Calibration
    static let requiresCalibration = true
    static let calibrationSamples = 10
}
```

### Body Region Mapping

```swift
enum BodyRegionMapping {
    case head       // pitch > 45°
    case torso      // pitch -15° to 45°
    case arms       // roll > 30° or < -30°
    case legs       // pitch < -15°
    
    static func region(from orientation: DeviceOrientation) -> BodyRegion {
        let pitchDegrees = orientation.pitch * 180 / .pi
        let rollDegrees = abs(orientation.roll * 180 / .pi)
        
        if pitchDegrees > 45 {
            return .head
        } else if pitchDegrees < -15 {
            return .legs
        } else if rollDegrees > 30 {
            return .arms
        } else {
            return .torso
        }
    }
    
    static func side(from orientation: DeviceOrientation) -> BodySide {
        let rollDegrees = orientation.roll * 180 / .pi
        
        if rollDegrees > 30 {
            return .right
        } else if rollDegrees < -30 {
            return .left
        } else if abs(orientation.yaw * 180 / .pi) > 135 {
            return .back
        } else {
            return .center
        }
    }
}
```

## Machine Learning Spezifikationen

**Status:** Nicht implementiert

Machine Learning Features sind für zukünftige Versionen geplant:
- Automatische Leberfleck-Erkennung
- Feature-Extraktion für Bildvergleich
- Automatische Zuordnung neuer Bilder
- Änderungs-Detektion

## Bildvergleich Spezifikationen

### Implementierte Features

**ComparisonView:**
- Side-by-Side Vergleich
- Overlay-Modus mit Transparenz-Slider
- Pinch-to-Zoom und Pan
- Swap-Funktion zum Bildertausch
- Datumsanzeige für beide Bilder

**Guided Comparison:**
- Systematischer Durchlauf aller Leberflecke
- Fortschrittsanzeige
- Inline-Notizen-Bearbeitung
- Überspringen-Funktion
- Statistiken am Ende

### Referenzbild-Auswahl

```swift
// Mole.swift
var referenceImage: MoleImage? {
    // Wenn spezifisches Referenzbild gesetzt
    if let refID = referenceImageID,
       let image = images.first(where: { $0.id == refID }) {
        return image
    }
    // Sonst: ältestes Bild als Standard
    return images.sorted(by: { $0.captureDate < $1.captureDate }).first
}
```

## Storage Spezifikationen

### Image Compression

```swift
struct ImageCompressionSettings {
    // Full Image
    static let fullImageQuality: CGFloat = 0.9
    static let fullImageMaxSize: Int = 10 * 1024 * 1024 // 10 MB
    
    // Thumbnail
    static let thumbnailSize = CGSize(width: 200, height: 200)
    static let thumbnailQuality: CGFloat = 0.7
    static let thumbnailMaxSize: Int = 100 * 1024 // 100 KB
}
```

### Database Limits

```swift
struct DatabaseLimits {
    static let maxMolesPerUser = 1000
    static let maxImagesPerMole = 50
    static let maxTotalImages = 5000
    static let maxStorageSize: Int64 = 5 * 1024 * 1024 * 1024 // 5 GB
}
```

### iCloud Sync

**Status:** Automatisch via SwiftData

SwiftData bietet automatische iCloud-Synchronisation:
- Keine manuelle CloudKit-Konfiguration erforderlich
- Automatische Konfliktauflösung
- Opt-in durch Benutzer in iOS-Einstellungen
- Verschlüsselte Übertragung

### AirDrop Sync (Implementiert)

**Manuelle Geräte-zu-Gerät Synchronisation:**
- Export als .nevus Paket (ZIP)
- Delta-Sync (nur neue Daten seit Datum)
- UUID-basierte Duplikat-Erkennung
- Automatischer Import via AirDrop
- Keine Cloud-Abhängigkeit
- Vollständige Privatsphäre

**Siehe:** `Documentation/Features/AIRDROP_SYNC_IMPLEMENTATION_COMPLETE.md`

## Performance-Anforderungen

### Response Times

| Operation | Target | Maximum |
|-----------|--------|---------|
| App Launch | < 2s | < 3s |
| Camera Open | < 1s | < 2s |
| Photo Capture | < 1s | < 2s |
| ML Inference | < 500ms | < 1s |
| Image Load | < 200ms | < 500ms |
| Mole List Load | < 300ms | < 1s |
| Comparison View | < 500ms | < 1s |
| CloudKit Sync | < 5s | < 10s |

### Memory Limits

```swift
struct MemoryLimits {
    static let maxImageCacheSize: Int = 100 * 1024 * 1024 // 100 MB
    static let maxThumbnailCacheSize: Int = 20 * 1024 * 1024 // 20 MB
    static let maxMLModelMemory: Int = 50 * 1024 * 1024 // 50 MB
}
```

### Battery Consumption

- **Target**: < 5% pro Stunde aktiver Nutzung
- **ML Inference**: Optimiert für Neural Engine
- **Background Sync**: Nur bei WLAN und Ladung
- **Location Services**: Nicht verwendet (keine GPS-Daten)

## Sicherheit und Datenschutz

### Data Encryption

```swift
struct SecurityConfiguration {
    // Local Storage
    static let useFileProtection = true
    static let fileProtectionLevel: FileProtectionType = .complete
    
    // CloudKit
    static let useEncryption = true
    static let encryptionType: CKRecordZone.Capabilities = .fetchChanges
    
    // Biometric Authentication
    static let requireBiometrics = true
    static let biometricPolicy: LAPolicy = .deviceOwnerAuthenticationWithBiometrics
}
```

### Privacy Settings

```swift
struct PrivacySettings {
    // Data Collection
    static let collectLocation = false // Not used - no GPS data
    static let collectAnalytics = false // Opt-in
    static let shareWithHealthKit = false // Opt-in
    
    // Data Retention
    static let autoDeleteAfterDays: Int? = nil // Never auto-delete
    static let exportFormat: ExportFormat = .pdf
}
```

## API-Versionen

### Implementierte API Versions

```swift
struct APIVersions {
    static let swiftVersion = "5.9+"
    static let iOS = "17.6+"
    static let swiftUI = "5.0"
    static let swiftData = "1.0"
    static let avFoundation = "1.0"
}
```

**Nicht verwendet:**
- Core ML (geplant für Phase 2)
- Vision Framework (geplant für Phase 2)
- CoreMotion (geplant für Phase 2)
- CloudKit (SwiftData nutzt automatisch iCloud)

## Testing-Spezifikationen

### Unit Test Coverage

- **Target**: > 80% Code Coverage
- **Critical Paths**: 100% Coverage
  - Matching Algorithm
  - Sensor Data Processing
  - ML Feature Extraction
  - Data Persistence

### Performance Tests

```swift
struct PerformanceTestTargets {
    static let imageLoadTime: TimeInterval = 0.5
    static let mlInferenceTime: TimeInterval = 1.0
    static let matchingAlgorithmTime: TimeInterval = 2.0
    static let syncTime: TimeInterval = 10.0
}
```

### UI Test Scenarios

1. **Happy Path**: Aufnahme → Automatische Zuordnung → Datumsauswahl → Vergleich
2. **Manual Assignment**: Aufnahme → Manuelle Auswahl → Speichern
3. **Comparison Flow**: Mole auswählen → Datum wählen → Bilder vergleichen → Notizen
4. **Sync Flow**: Offline-Aufnahme → Online → Sync → Konflikt
5. **Error Handling**: Kamera-Fehler, Speicher voll, Netzwerk-Fehler

## Accessibility-Anforderungen

### VoiceOver Support

- Alle UI-Elemente mit aussagekräftigen Labels
- Kamera-Feedback akustisch
- Bildvergleich beschreibbar
- Navigation vollständig per VoiceOver

### Dynamic Type

- Alle Texte skalierbar
- Minimum: Large
- Maximum: AX5
- Layout-Anpassung bei Größenänderung

### Color Contrast

- WCAG AA Standard (4.5:1 für Text)
- Farbunabhängige Informationen
- Dark Mode Support

## Lokalisierung

### Implementierte Sprachen

- 🇩🇪 Deutsch (de) - Basissprache
- 🇬🇧 Englisch (en) - Vollständig

**Format:** String Catalog (`Localizable.xcstrings`)

**Lokalisierte Komponenten:**
- Alle UI-Texte
- Body Regions (12 Regionen)
- Body Sides (26 Seiten)
- Fehlermeldungen
- Guided Scanning
- Guided Comparison
- AirDrop Sync
- Export/Import

**Siehe:** `Documentation/INTERNATIONALIZATION.md`

### Geplante Erweiterungen

- Französisch (fr)
- Spanisch (es)
- Italienisch (it)

## Monitoring und Analytics

### Error Tracking

```swift
struct ErrorTracking {
    static let trackCrashes = true
    static let trackErrors = true
    static let trackPerformance = true
    
    // Privacy-preserving
    static let anonymizeUserData = true
    static let excludeHealthData = true
}
```

### Performance Metrics

- App Launch Time
- Screen Load Times
- ML Inference Duration
- Network Request Duration
- Memory Usage
- Battery Impact

## Deployment

### Build Configuration

```swift
struct BuildConfiguration {
    #if DEBUG
    static let environment = "Development"
    static let apiEndpoint = "https://dev.api.nevus.com"
    static let logLevel = "verbose"
    #else
    static let environment = "Production"
    static let apiEndpoint = "https://api.nevus.com"
    static let logLevel = "error"
    #endif
}
```

### App Store Metadata

- **Category**: Health & Fitness
- **Age Rating**: 4+
- **Privacy Labels**: Required
- **In-App Purchases**: None (Phase 1)
- **Subscriptions**: None (Phase 1)

## Implementierte Features (Stand März 2026)

### ✅ Core Features
- SwiftData Persistenz mit iCloud Backup
- Kamera-Integration (AVFoundation)
- 12 Körperregionen, 26 Körperseiten
- Mehrere Bilder pro Leberfleck
- Bearbeitbare Notizen
- Referenzbild-Auswahl für Overlay

### ✅ Bildvergleich
- Side-by-Side Vergleich
- Overlay-Modus mit Transparenz
- Pinch-to-Zoom und Pan
- Swap-Funktion

### ✅ Übersichtsbilder
- Körperregion-Übersichtsbilder
- Inline-Anzeige in Hauptansicht
- Detailansicht mit Zoom
- Notizen pro Übersichtsbild
- Verknüpfung mit Leberflecken (MoleLocationMarker)

### ✅ Guided Features
- Guided Scanning (systematisches Fotografieren)
- Guided Comparison (systematischer Vergleich)
- Fortschrittsanzeige
- Statistiken

### ✅ Export/Import
- Einzelner Leberfleck (ZIP)
- Alle Leberflecke (ZIP)
- Einzelnes Bild (JPEG)
- AirDrop Sync (.nevus Pakete)
- Delta-Sync (nur neue Daten)

### ✅ iPad-Unterstützung
- NavigationSplitView (Master-Detail)
- Adaptive Layouts
- Größere Grids
- Multitasking-Support

### ✅ Weitere Features
- Internationalisierung (DE/EN)
- Session Cleanup
- Monatliche Erinnerungen
- Overlay-Modus mit Referenzbild
- Löschen mit Bestätigung

## Zukünftige Erweiterungen

### Phase 2 (Geplant)

- ✅ ~~iPad-Optimierung~~ (Implementiert)
- Core ML Integration
- Automatische Leberfleck-Erkennung
- Sensordaten (CoreMotion)
- Änderungs-Detektion mit ML
- PDF-Export für Ärzte
- Erweiterte Statistiken

### Phase 3 (Geplant)

- Apple Watch Companion App
- HealthKit Integration
- Familien-Sharing
- Dermatologen-Portal
- Risiko-Analyse mit ML

### Phase 4 (Vision)

- AR-basierte Körperkarte
- 3D-Scanning
- Telemedicine-Integration
- KI-gestützte Früherkennung