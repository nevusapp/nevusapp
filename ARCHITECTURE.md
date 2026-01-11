# MoleTracker - iOS App Architektur

## Projektübersicht

**MoleTracker** ist eine native iOS-App zur Erfassung, Katalogisierung und Überwachung von Leberflecken. Die App nutzt iPhone-Sensoren und Machine Learning für automatische Zuordnung und Vergleich von Aufnahmen.

## Technologie-Stack

- **Plattform**: iOS 16+
- **Sprache**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Datenpersistenz**: SwiftData (iOS 17) / Core Data (iOS 16 Fallback)
- **Cloud-Sync**: CloudKit
- **ML Framework**: Core ML + Vision Framework
- **Sensoren**: CoreMotion, AVFoundation

## Architektur-Muster

### MVVM (Model-View-ViewModel)

```
┌─────────────────────────────────────────────────────────┐
│                         Views                            │
│  (SwiftUI: CameraView, MoleListView, ComparisonView)   │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                      ViewModels                          │
│   (CameraViewModel, MoleListViewModel, etc.)            │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                       Services                           │
│  (CameraService, SensorService, MLService, etc.)        │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                    Data Layer                            │
│        (SwiftData Models, CloudKit Sync)                │
└─────────────────────────────────────────────────────────┘
```

## Kern-Komponenten

### 1. Datenmodell

```swift
@Model
class Mole {
    var id: UUID
    var createdAt: Date
    var bodyLocation: BodyLocation
    var images: [MoleImage]
    var notes: String?
    
    // Computed properties
    var latestImage: MoleImage?
    var changeHistory: [MoleComparison]
}

@Model
class MoleImage {
    var id: UUID
    var captureDate: Date
    var imageData: Data
    var thumbnail: Data
    
    // Sensor data
    var deviceOrientation: DeviceOrientation
    var tiltAngle: TiltAngle
    var barometricPressure: Double?
    
    // ML features
    var mlFeatureVector: [Float]
    var confidence: Float
}

struct BodyLocation {
    var region: BodyRegion // head, torso, arms, legs
    var side: BodySide // left, right, center
    var coordinates: CGPoint // 2D body map coordinates
}

struct TiltAngle {
    var pitch: Double
    var roll: Double
    var yaw: Double
}
```

### 2. Service-Layer

#### CameraService
- Kamera-Initialisierung und Konfiguration
- Hochauflösende Bildaufnahme
- Live-Preview mit Overlay-Guides
- Fokus- und Belichtungssteuerung

#### SensorService
- CoreMotion-Integration für Geräteneigung
- Barometer-Daten (Höhenänderung)
- Sensor-Fusion für präzise Orientierung

#### MLService
- Core ML Modell-Integration
- Mole-Feature-Extraktion
- Bildvergleich und Ähnlichkeitsberechnung
- Automatische Mole-Zuordnung

#### StorageService
- SwiftData/Core Data Operationen
- Bildkompression und -optimierung
- CloudKit-Synchronisation
- Lokales Caching

### 3. ML-Pipeline

```
Kamera-Bild
    │
    ▼
┌─────────────────────┐
│  Bild-Preprocessing │
│  - Resize           │
│  - Normalisierung   │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Vision Framework   │
│  - Hautbereich      │
│  - Mole-Detektion   │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Core ML Model      │
│  - Feature Extract  │
│  - Klassifizierung  │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Matching Algorithm │
│  - Sensor-Daten     │
│  - Feature-Vergleich│
│  - Confidence Score │
└─────────────────────┘
```

### 4. Matching-Algorithmus

Die automatische Zuordnung kombiniert mehrere Faktoren:

1. **Sensor-basiertes Matching** (45% Gewichtung)
   - Körperregion basierend auf Geräteneigung
   - Höhenänderung (Barometer) für vertikale Position

2. **ML-Feature-Matching** (55% Gewichtung)
   - Cosine-Similarity der Feature-Vektoren
   - Größe und Form des Leberflecks
   - Farbprofil und Textur

**Hinweis**: Für Vergleiche wählt der Benutzer manuell aus vorherigen Aufnahmen basierend auf dem Aufnahmedatum.

**Confidence-Schwellwerte:**
- > 0.85: Automatische Zuordnung
- 0.70-0.85: Vorschlag mit Bestätigung
- < 0.70: Manuelle Auswahl erforderlich

## UI-Struktur

### Hauptansichten

1. **HomeView**
   - Dashboard mit Statistiken
   - Letzte Aufnahmen
   - Erinnerungen für regelmäßige Checks

2. **BodyMapView**
   - Interaktive 2D-Körperkarte
   - Mole-Marker mit Farbcodierung (neu, überwacht, verändert)
   - Zoom und Pan-Funktionalität

3. **CameraView**
   - Live-Kamera-Preview
   - Overlay-Guides für konsistente Aufnahmen
   - Sensor-Feedback (Neigung, Stabilität)
   - Automatische Mole-Vorschläge

4. **MoleDetailView**
   - Bildergalerie mit Timeline
   - Datumsbasierte Auswahl für Vergleich
   - Notizen und Metadaten
   - Änderungsverlauf

5. **ComparisonView**
   - Zwei Bilder nebeneinander (manuell ausgewählt nach Datum)
   - Slider für Overlay-Vergleich
   - Differenz-Highlighting
   - Messtools (Größe, Farbe)
   - Datums-Anzeige für beide Aufnahmen

## Datenschutz und Sicherheit

### Lokale Speicherung
- Alle Bilder verschlüsselt in App-Container
- Keine Weitergabe an Dritte
- Biometrische Authentifizierung (Face ID/Touch ID)

### iCloud-Sync
- End-to-End-Verschlüsselung via CloudKit
- Opt-in für Cloud-Backup
- Automatische Konfliktauflösung

### Berechtigungen
- Kamera-Zugriff (erforderlich)
- Foto-Bibliothek (optional, für Export)
- Bewegungs- und Fitness-Daten (CoreMotion)
- Standort (optional, für Kontext)

## Performance-Optimierungen

1. **Bildverarbeitung**
   - Asynchrone Verarbeitung mit async/await
   - Thumbnail-Generierung für Listen
   - Lazy Loading von Vollbildern

2. **ML-Inferenz**
   - On-Device-Verarbeitung (keine Cloud)
   - Batch-Processing für mehrere Bilder
   - Caching von Feature-Vektoren

3. **Datenbank**
   - Indizierung für schnelle Suche
   - Pagination für große Datensätze
   - Hintergrund-Sync mit CloudKit

## Erweiterungsmöglichkeiten

### Phase 1 (MVP)
- Grundlegende Erfassung und Katalogisierung
- Manuelle Zuordnung mit Sensor-Unterstützung
- Einfacher Bildvergleich

### Phase 2
- Core ML Integration
- Automatische Zuordnung
- Erweiterte Vergleichstools

### Phase 3
- Änderungs-Detektion mit Alerts
- Export für Ärzte (PDF-Report)
- Apple Watch Companion App

### Phase 4
- Erweiterte ML-Modelle (Risiko-Einschätzung)
- HealthKit-Integration
- Teilen mit Dermatologen

## Entwicklungs-Workflow

```
Design → Prototyping → Implementation → Testing → Review
   ↓          ↓              ↓             ↓         ↓
Figma    SwiftUI      Unit Tests    UI Tests   Beta
         Previews     Integration   Snapshot   TestFlight
```

## Abhängigkeiten

### Apple Frameworks
- SwiftUI
- SwiftData / Core Data
- CloudKit
- Core ML
- Vision
- CoreMotion
- CoreLocation
- AVFoundation
- PhotosUI

### Drittanbieter (Optional)
- Keine erforderlich für MVP
- Mögliche Ergänzungen: Charts-Library für Statistiken

## Deployment

- **Minimum iOS Version**: 16.0
- **Target Devices**: iPhone (iPad-Unterstützung optional)
- **Distribution**: TestFlight → App Store
- **App Store Kategorie**: Gesundheit & Fitness
- **Privacy Nutrition Labels**: Erforderlich

## Nächste Schritte

1. Xcode-Projekt erstellen
2. SwiftData-Modelle implementieren
3. Basis-UI mit SwiftUI aufbauen
4. Kamera-Integration
5. Sensor-Service implementieren
6. ML-Modell trainieren/integrieren
7. Testing und Iteration