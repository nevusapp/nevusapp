# Nevus - Technische Spezifikationen

## System-Anforderungen

### Minimum Requirements
- **iOS Version**: 16.0+
- **Device**: iPhone 12 oder neuer (empfohlen für beste Kamera-Qualität)
- **Storage**: 500 MB freier Speicher (minimal)
- **RAM**: 3 GB (für ML-Verarbeitung)
- **Kamera**: Dual-Kamera-System (für bessere Bildqualität)
- **Sensoren**: Gyroskop, Accelerometer, Barometer

### Empfohlene Requirements
- **iOS Version**: 17.0+
- **Device**: iPhone 14 Pro oder neuer
- **Storage**: 2 GB freier Speicher
- **iCloud**: Aktives iCloud-Konto für Sync

## Datenmodell-Spezifikationen

### Mole Entity

| Feld | Typ | Beschreibung | Constraints |
|------|-----|--------------|-------------|
| `id` | UUID | Eindeutige Kennung | Primary Key, Unique |
| `createdAt` | Date | Erstellungsdatum | Not Null |
| `lastModified` | Date | Letzte Änderung | Not Null, Auto-update |
| `bodyRegion` | String | Körperregion | Enum: head, torso, arms, legs |
| `bodySide` | String | Körperseite | Enum: left, right, center, back |
| `bodyMapX` | Double | X-Koordinate auf Körperkarte | 0.0 - 1.0 |
| `bodyMapY` | Double | Y-Koordinate auf Körperkarte | 0.0 - 1.0 |
| `notes` | String | Benutzer-Notizen | Optional, max 1000 Zeichen |
| `isArchived` | Bool | Archiviert-Status | Default: false |
| `riskLevel` | String | Risiko-Einschätzung | Enum: low, medium, high, unknown |

**Relationships:**
- `images`: One-to-Many zu MoleImage (Cascade Delete)

### MoleImage Entity

| Feld | Typ | Beschreibung | Constraints |
|------|-----|--------------|-------------|
| `id` | UUID | Eindeutige Kennung | Primary Key, Unique |
| `captureDate` | Date | Aufnahmedatum | Not Null |
| `imageData` | Data | Vollbild (JPEG) | Not Null, max 10 MB |
| `thumbnailData` | Data | Thumbnail (JPEG) | Not Null, max 100 KB |
| `imageWidth` | Int | Bildbreite in Pixel | Not Null |
| `imageHeight` | Int | Bildhöhe in Pixel | Not Null |

**Sensor Data:**
| Feld | Typ | Beschreibung | Constraints |
|------|-----|--------------|-------------|
| `pitch` | Double | Neigung vorwärts/rückwärts | -π bis π |
| `roll` | Double | Neigung links/rechts | -π bis π |
| `yaw` | Double | Rotation um vertikale Achse | -π bis π |
| `barometricPressure` | Double? | Luftdruck in kPa | Optional |
| `altitude` | Double? | Relative Höhe in Metern | Optional |
| `deviceOrientation` | String | Geräte-Orientierung | Enum: portrait, landscape |

**ML Features:**
| Feld | Typ | Beschreibung | Constraints |
|------|-----|--------------|-------------|
| `featureVector` | [Float] | ML-Feature-Vektor | 512 Dimensionen |
| `matchConfidence` | Float | Zuordnungs-Konfidenz | 0.0 - 1.0 |
| `mlModelVersion` | String | Verwendete Modell-Version | Not Null |

**Relationships:**
- `mole`: Many-to-One zu Mole

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

### Model Architecture

**Feature Extraction Model:**
- **Base**: MobileNetV3-Large
- **Input**: 224x224 RGB Image
- **Output**: 512-dimensional feature vector
- **Format**: Core ML (.mlmodel)
- **Size**: ~15 MB
- **Inference Time**: < 100ms (iPhone 12+)

### Feature Vector Specifications

```swift
struct MLFeatureVector {
    static let dimensions = 512
    static let normalization: NormalizationType = .l2
    static let dataType: MLMultiArrayDataType = .float32
}
```

### Similarity Metrics

```swift
struct SimilarityMetrics {
    // Cosine Similarity
    static func cosineSimilarity(_ v1: [Float], _ v2: [Float]) -> Float {
        let dotProduct = zip(v1, v2).map(*).reduce(0, +)
        let magnitude1 = sqrt(v1.map { $0 * $0 }.reduce(0, +))
        let magnitude2 = sqrt(v2.map { $0 * $0 }.reduce(0, +))
        return dotProduct / (magnitude1 * magnitude2)
    }
    
    // Euclidean Distance
    static func euclideanDistance(_ v1: [Float], _ v2: [Float]) -> Float {
        return sqrt(zip(v1, v2).map { pow($0 - $1, 2) }.reduce(0, +))
    }
}
```

## Matching-Algorithmus Spezifikationen

### Scoring Weights

```swift
struct MatchingWeights {
    static let sensorScore: Float = 0.45
    static let featureScore: Float = 0.55
    static let temporalScore: Float = 0.0  // Not used - manual date selection
}
```

### Confidence Thresholds

```swift
struct ConfidenceThresholds {
    static let autoAssign: Float = 0.85      // Automatische Zuordnung
    static let suggestWithConfirm: Float = 0.70  // Vorschlag mit Bestätigung
    static let manualSelection: Float = 0.70     // Manuelle Auswahl erforderlich
}
```

### Sensor Similarity Calculation

```swift
func calculateSensorSimilarity(
    new: MoleImage,
    existing: MoleImage
) -> Float {
    // Angle difference (normalized to 0-1)
    let pitchDiff = abs(new.pitch - existing.pitch) / .pi
    let rollDiff = abs(new.roll - existing.roll) / .pi
    let yawDiff = abs(new.yaw - existing.yaw) / .pi
    
    let angleSimilarity = 1.0 - (pitchDiff + rollDiff + yawDiff) / 3.0
    
    // Altitude difference (if available)
    var altitudeSimilarity: Float = 1.0
    if let newAlt = new.altitude, let existingAlt = existing.altitude {
        let altDiff = abs(newAlt - existingAlt)
        altitudeSimilarity = max(0, 1.0 - Float(altDiff) / 2.0) // 2m threshold
    }
    
    // Weighted combination (no GPS data used)
    return angleSimilarity * 0.7 + altitudeSimilarity * 0.3
}
```

### Temporal Score Calculation

**Note**: Temporal scoring is not used in automatic matching. Users manually select which previous images to compare based on capture date through the UI.

```swift
// Not used - manual date selection in UI
func calculateTemporalScore(
    new: MoleImage,
    existing: MoleImage
) -> Float {
    return 0.0  // Manual selection via date picker
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

### CloudKit Configuration

```swift
struct CloudKitConfiguration {
    static let containerIdentifier = "iCloud.com.yourcompany.nevus"
    static let databaseScope: CKDatabase.Scope = .private
    
    // Sync Settings
    static let syncInterval: TimeInterval = 300 // 5 minutes
    static let batchSize = 50
    static let maxRetries = 3
    
    // Conflict Resolution
    static let conflictResolution: ConflictResolutionStrategy = .latestWins
}
```

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

### Minimum API Versions

```swift
struct APIVersions {
    static let swiftVersion = "5.9"
    static let iOS = "16.0"
    static let swiftUI = "4.0"
    static let coreML = "7.0"
    static let vision = "5.0"
    static let coreMotion = "1.0"
    static let cloudKit = "1.0"
}
```

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

### Unterstützte Sprachen (Phase 1)

- Deutsch (de)
- Englisch (en)

### Erweiterung (Phase 2+)

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

## Zukünftige Erweiterungen

### Phase 2 Features

- Apple Watch Companion App
- HealthKit Integration
- Export für Ärzte (PDF)
- Erweiterte Statistiken

### Phase 3 Features

- iPad-Optimierung
- Familien-Sharing
- Dermatologen-Portal
- Risiko-Analyse mit ML

### Phase 4 Features

- AR-basierte Körperkarte
- 3D-Scanning
- Telemedicine-Integration
- KI-gestützte Früherkennung