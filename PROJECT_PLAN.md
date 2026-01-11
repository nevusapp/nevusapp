# MoleTracker - Detaillierter Projektplan

## Projektziel

Entwicklung einer nativen iOS-App zur systematischen Erfassung, Katalogisierung und Überwachung von Leberflecken mit automatischer Zuordnung durch Sensordaten und Machine Learning.

## Technische Spezifikationen

- **Plattform**: iOS 16+
- **Entwicklungssprache**: Swift 5.9+
- **UI**: SwiftUI
- **Datenpersistenz**: SwiftData (mit Core Data Fallback)
- **Cloud**: CloudKit für iCloud-Synchronisation
- **ML**: Core ML + Vision Framework
- **Sensoren**: CoreMotion, Barometer

## Entwicklungsphasen

### Phase 1: Projekt-Setup und Grundstruktur (Woche 1-2)

#### 1.1 Xcode-Projekt erstellen
- Neues iOS-Projekt in Xcode anlegen
- Bundle Identifier festlegen
- Deployment Target auf iOS 16.0 setzen
- SwiftUI als Interface-Framework wählen
- SwiftData als Storage-Option aktivieren

#### 1.2 Projekt-Struktur aufbauen
```
MoleTracker/
├── App/
│   ├── MoleTrackerApp.swift
│   └── AppDelegate.swift
├── Models/
│   ├── Mole.swift
│   ├── MoleImage.swift
│   ├── BodyLocation.swift
│   └── SensorData.swift
├── ViewModels/
│   ├── CameraViewModel.swift
│   ├── MoleListViewModel.swift
│   ├── MoleDetailViewModel.swift
│   └── BodyMapViewModel.swift
├── Views/
│   ├── Home/
│   ├── Camera/
│   ├── MoleList/
│   ├── MoleDetail/
│   ├── BodyMap/
│   └── Comparison/
├── Services/
│   ├── CameraService.swift
│   ├── SensorService.swift
│   ├── MLService.swift
│   ├── StorageService.swift
│   └── CloudSyncService.swift
├── Utilities/
│   ├── Extensions/
│   ├── Constants.swift
│   └── Helpers.swift
└── Resources/
    ├── Assets.xcassets
    └── Localizable.strings
```

#### 1.3 Berechtigungen konfigurieren
Info.plist Einträge:
- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`
- `NSMotionUsageDescription`

#### 1.4 Dependencies und Frameworks
- CloudKit Capability aktivieren
- Core ML Framework hinzufügen
- Vision Framework hinzufügen
- CoreMotion Framework hinzufügen

### Phase 2: Datenmodell und Persistenz (Woche 2-3)

#### 2.1 SwiftData Models erstellen

**Mole Model:**
```swift
@Model
final class Mole {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var lastModified: Date
    var bodyRegion: String
    var bodySide: String
    var bodyMapX: Double
    var bodyMapY: Double
    var notes: String
    
    @Relationship(deleteRule: .cascade)
    var images: [MoleImage]
    
    init(bodyRegion: String, bodySide: String, x: Double, y: Double) {
        self.id = UUID()
        self.createdAt = Date()
        self.lastModified = Date()
        self.bodyRegion = bodyRegion
        self.bodySide = bodySide
        self.bodyMapX = x
        self.bodyMapY = y
        self.notes = ""
        self.images = []
    }
}
```

**MoleImage Model:**
```swift
@Model
final class MoleImage {
    @Attribute(.unique) var id: UUID
    var captureDate: Date
    var imageData: Data
    var thumbnailData: Data
    
    // Sensor data
    var pitch: Double
    var roll: Double
    var yaw: Double
    var barometricPressure: Double?
    var altitude: Double?
    
    // ML features
    var featureVector: [Float]
    var matchConfidence: Float
    
    var mole: Mole?
    
    init(imageData: Data, thumbnailData: Data) {
        self.id = UUID()
        self.captureDate = Date()
        self.imageData = imageData
        self.thumbnailData = thumbnailData
        self.pitch = 0
        self.roll = 0
        self.yaw = 0
        self.featureVector = []
        self.matchConfidence = 0
    }
}
```

#### 2.2 ModelContainer konfigurieren
```swift
@main
struct MoleTrackerApp: App {
    let modelContainer: ModelContainer
    
    init() {
        do {
            modelContainer = try ModelContainer(
                for: Mole.self, MoleImage.self,
                configurations: ModelConfiguration(
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .private("iCloud.com.yourcompany.moletracker")
                )
            )
        } catch {
            fatalError("Could not initialize ModelContainer")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
```

#### 2.3 StorageService implementieren
- CRUD-Operationen für Moles
- Bildkompression und -optimierung
- Thumbnail-Generierung
- Batch-Operationen
- Fehlerbehandlung

### Phase 3: Kamera-Integration (Woche 3-4)

#### 3.1 CameraService erstellen
- AVCaptureSession Setup
- Hochauflösende Foto-Konfiguration
- Live-Preview mit AVCaptureVideoPreviewLayer
- Fokus- und Belichtungssteuerung
- Bildstabilisierung

#### 3.2 CameraView (SwiftUI)
- Kamera-Preview-Integration
- Auslöser-Button
- Overlay-Guides für konsistente Aufnahmen
- Sensor-Feedback-Anzeige (Neigung, Stabilität)
- Flash-Steuerung

#### 3.3 Bildverarbeitung
- Hochauflösende Bildaufnahme
- EXIF-Daten extrahieren
- Bildrotation korrigieren
- Thumbnail-Generierung
- Kompression für Speicherung

### Phase 4: Sensor-Integration (Woche 4-5)

#### 4.1 SensorService implementieren

**CoreMotion Integration:**
```swift
class SensorService: ObservableObject {
    private let motionManager = CMMotionManager()
    private let altimeter = CMAltimeter()
    
    @Published var currentOrientation: DeviceOrientation?
    @Published var barometricPressure: Double?
    
    func startMonitoring() {
        // Device Motion (Pitch, Roll, Yaw)
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.1
            motionManager.startDeviceMotionUpdates(to: .main) { motion, error in
                guard let motion = motion else { return }
                self.currentOrientation = DeviceOrientation(
                    pitch: motion.attitude.pitch,
                    roll: motion.attitude.roll,
                    yaw: motion.attitude.yaw
                )
            }
        }
        
        // Barometer
        if CMAltimeter.isRelativeAltitudeAvailable() {
            altimeter.startRelativeAltitudeUpdates(to: .main) { data, error in
                guard let data = data else { return }
                self.barometricPressure = data.pressure.doubleValue
            }
        }
    }
}
```

#### 4.2 Sensor-Daten-Erfassung
- Geräteneigung (Pitch, Roll, Yaw)
- Barometrischer Druck
- Relative Höhenänderung
- Zeitstempel-Synchronisation

#### 4.3 Körperregion-Mapping
Algorithmus zur Bestimmung der Körperregion basierend auf:
- Geräteneigung → Körperteil (Kopf, Torso, Arme, Beine)
- Höhenänderung → Vertikale Position
- Seitliche Neigung → Links/Rechts/Mitte

### Phase 5: Machine Learning Integration (Woche 5-7)

#### 5.1 ML-Modell vorbereiten

**Option A: Transfer Learning mit vortrainiertem Modell**
- MobileNetV3 oder EfficientNet als Basis
- Feature-Extraktion für Hautbilder
- Fine-Tuning auf Leberfleck-Daten

**Option B: Custom Core ML Modell**
- Eigenes CNN-Modell trainieren
- Create ML für einfaches Training
- Konvertierung zu Core ML Format

#### 5.2 MLService implementieren
```swift
class MLService {
    private var model: VNCoreMLModel?
    
    func extractFeatures(from image: UIImage) async throws -> [Float] {
        guard let model = model else { throw MLError.modelNotLoaded }
        
        let request = VNCoreMLRequest(model: model)
        let handler = VNImageRequestHandler(cgImage: image.cgImage!)
        
        try handler.perform([request])
        
        guard let results = request.results as? [VNFeatureObservation] else {
            throw MLError.featureExtractionFailed
        }
        
        return results.first?.featureVector ?? []
    }
    
    func calculateSimilarity(vector1: [Float], vector2: [Float]) -> Float {
        // Cosine Similarity
        let dotProduct = zip(vector1, vector2).map(*).reduce(0, +)
        let magnitude1 = sqrt(vector1.map { $0 * $0 }.reduce(0, +))
        let magnitude2 = sqrt(vector2.map { $0 * $0 }.reduce(0, +))
        return dotProduct / (magnitude1 * magnitude2)
    }
}
```

#### 5.3 Vision Framework Integration
- Hautbereich-Detektion
- Leberfleck-Segmentierung
- Feature-Extraktion
- Bildqualitäts-Bewertung

### Phase 6: Matching-Algorithmus (Woche 7-8)

#### 6.1 Multi-Faktor-Matching implementieren

```swift
struct MoleMatchingService {
    func findBestMatch(
        for newImage: MoleImage,
        in existingMoles: [Mole]
    ) -> (mole: Mole?, confidence: Float)? {
        
        var bestMatch: (Mole, Float)?
        
        for mole in existingMoles {
            guard let latestImage = mole.images.last else { continue }
            
            // 1. Sensor-based matching (45%)
            let sensorScore = calculateSensorSimilarity(
                newImage: newImage,
                existingImage: latestImage
            ) * 0.45
            
            // 2. ML feature matching (55%)
            let featureScore = calculateFeatureSimilarity(
                newImage: newImage,
                existingImage: latestImage
            ) * 0.55
            
            // Note: Temporal context not used - manual date selection in UI
            
            let totalScore = sensorScore + featureScore
            
            if bestMatch == nil || totalScore > bestMatch!.1 {
                bestMatch = (mole, totalScore)
            }
        }
        
        // Confidence thresholds
        if let match = bestMatch {
            if match.1 > 0.85 {
                return match // Auto-assign
            } else if match.1 > 0.70 {
                return match // Suggest with confirmation
            }
        }
        
        return nil // Manual selection required
    }
}
```

#### 6.2 Sensor-Similarity-Berechnung
- Winkel-Differenz (Pitch, Roll, Yaw)
- Höhen-Differenz (Barometer)
- Körperregion-Übereinstimmung
- Gewichtete Kombination

#### 6.3 Feature-Similarity-Berechnung
- Cosine-Similarity der Feature-Vektoren
- Größen-Vergleich
- Farb-Profil-Ähnlichkeit

### Phase 7: UI-Implementierung (Woche 8-11)

#### 7.1 HomeView
- Dashboard mit Statistiken
- Letzte Aufnahmen (Grid)
- Schnellzugriff auf Kamera
- Erinnerungen für regelmäßige Checks

#### 7.2 BodyMapView
- Interaktive 2D-Körperkarte (Front/Back)
- Mole-Marker mit Farbcodierung
- Tap-Gesten für Mole-Details
- Zoom und Pan
- Filter-Optionen

#### 7.3 CameraView (erweitert)
- Live-Preview mit Overlay
- Sensor-Feedback-Anzeige
- Automatische Mole-Vorschläge
- Capture-Button mit Feedback
- Galerie-Zugriff

#### 7.4 MoleListView
- Sortierbare Liste aller Moles
- Suchfunktion
- Filter (Datum, Körperregion, Änderungen)
- Swipe-Actions (Löschen, Bearbeiten)

#### 7.5 MoleDetailView
- Bildergalerie mit Timeline
- Metadaten-Anzeige
- Notizen-Editor
- Vergleichs-Button
- Teilen-Funktion

#### 7.6 ComparisonView
- Datumsbasierte Bildauswahl
- Side-by-Side-Vergleich
- Overlay-Slider
- Differenz-Highlighting
- Zoom-Synchronisation
- Datums-Anzeige für beide Aufnahmen
- Mess-Tools (optional)

### Phase 8: iCloud-Synchronisation (Woche 11-12)

#### 8.1 CloudKit-Setup
- Container-Konfiguration
- Schema-Definition
- Berechtigungen

#### 8.2 CloudSyncService
```swift
class CloudSyncService {
    private let container = CKContainer.default()
    
    func syncMoles() async throws {
        // SwiftData handles CloudKit sync automatically
        // Additional custom sync logic if needed
    }
    
    func resolveConflicts() async throws {
        // Conflict resolution strategy
        // Latest-wins or manual resolution
    }
}
```

#### 8.3 Sync-Strategie
- Automatische Synchronisation bei Netzwerk
- Konfliktauflösung (Latest-Wins)
- Offline-Modus mit Queue
- Sync-Status-Anzeige

### Phase 9: Testing und Qualitätssicherung (Woche 12-14)

#### 9.1 Unit Tests
- Model-Tests
- Service-Tests
- Matching-Algorithmus-Tests
- Sensor-Daten-Verarbeitung

#### 9.2 UI Tests
- Navigation-Flow
- Kamera-Funktionalität
- Bildvergleich
- Daten-Persistenz

#### 9.3 Integration Tests
- End-to-End-Workflows
- CloudKit-Sync
- ML-Pipeline
- Performance-Tests

#### 9.4 Beta-Testing
- TestFlight-Distribution
- Feedback-Sammlung
- Bug-Fixes
- Performance-Optimierung

### Phase 10: Polishing und Launch (Woche 14-16)

#### 10.1 UI/UX-Verfeinerung
- Animationen
- Haptic Feedback
- Accessibility (VoiceOver, Dynamic Type)
- Dark Mode

#### 10.2 Performance-Optimierung
- Bildlade-Performance
- ML-Inferenz-Geschwindigkeit
- Speicher-Management
- Batterie-Verbrauch

#### 10.3 Dokumentation
- Benutzerhandbuch
- Datenschutzerklärung
- App Store Beschreibung
- Screenshots und Videos

#### 10.4 App Store Vorbereitung
- App Store Connect Setup
- Metadata und Keywords
- Privacy Nutrition Labels
- Review-Einreichung

## Meilensteine

| Woche | Meilenstein | Deliverables |
|-------|-------------|--------------|
| 2 | Projekt-Setup abgeschlossen | Xcode-Projekt, Grundstruktur |
| 3 | Datenmodell fertig | SwiftData Models, Storage Service |
| 4 | Kamera funktionsfähig | Bildaufnahme, Preview |
| 5 | Sensoren integriert | Sensor-Daten-Erfassung |
| 7 | ML-Integration | Feature-Extraktion, Modell |
| 8 | Matching-Algorithmus | Automatische Zuordnung |
| 11 | UI vollständig | Alle Views implementiert |
| 12 | iCloud-Sync | CloudKit-Integration |
| 14 | Testing abgeschlossen | Alle Tests bestanden |
| 16 | App Store Launch | App veröffentlicht |

## Risiken und Mitigation

### Technische Risiken

1. **ML-Modell-Genauigkeit**
   - Risiko: Unzureichende Matching-Genauigkeit
   - Mitigation: Hybrid-Ansatz mit manueller Bestätigung

2. **Sensor-Präzision**
   - Risiko: Ungenaue Körperregion-Bestimmung
   - Mitigation: Benutzer-Feedback zur Kalibrierung

3. **Performance**
   - Risiko: Langsame Bildverarbeitung
   - Mitigation: Asynchrone Verarbeitung, Caching

4. **CloudKit-Sync**
   - Risiko: Sync-Konflikte
   - Mitigation: Robuste Konfliktauflösung

### Zeitliche Risiken

1. **ML-Modell-Training**
   - Risiko: Längere Trainingszeit
   - Mitigation: Vortrainierte Modelle nutzen

2. **UI-Komplexität**
   - Risiko: Zeitüberschreitung
   - Mitigation: MVP-Ansatz, iterative Verbesserung

## Erfolgs-Kriterien

### Funktionale Kriterien
- ✅ Bildaufnahme mit Sensor-Daten
- ✅ Automatische Zuordnung > 80% Genauigkeit
- ✅ Bildvergleich Side-by-Side
- ✅ iCloud-Synchronisation
- ✅ Offline-Funktionalität

### Nicht-funktionale Kriterien
- ✅ Bildaufnahme < 2 Sekunden
- ✅ ML-Inferenz < 1 Sekunde
- ✅ App-Start < 3 Sekunden
- ✅ Speicherverbrauch < 200 MB
- ✅ Batterieverbrauch < 5% pro Stunde

### Benutzer-Kriterien
- ✅ Intuitive Bedienung
- ✅ Klare Visualisierung
- ✅ Zuverlässige Daten-Sicherheit
- ✅ Schnelle Performance

## Nächste Schritte

1. ✅ Architektur-Dokument erstellt
2. ✅ Projekt-Plan erstellt
3. ⏭️ Xcode-Projekt anlegen
4. ⏭️ SwiftData-Modelle implementieren
5. ⏭️ Basis-UI aufbauen

## Ressourcen

### Apple Dokumentation
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [Core ML Documentation](https://developer.apple.com/documentation/coreml)
- [Vision Framework](https://developer.apple.com/documentation/vision)
- [CoreMotion Documentation](https://developer.apple.com/documentation/coremotion)
- [CloudKit Documentation](https://developer.apple.com/documentation/cloudkit)

### Tutorials und Guides
- WWDC Sessions zu SwiftData, Core ML, Vision
- Ray Wenderlich iOS Tutorials
- Hacking with Swift SwiftUI Guides

### Tools
- Xcode 15+
- Create ML für Modell-Training
- Instruments für Performance-Analyse
- TestFlight für Beta-Testing