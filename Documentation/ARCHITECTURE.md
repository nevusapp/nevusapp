# Nevus - iOS App Architektur

**Letzte Aktualisierung:** 15. März 2026
**Status:** Implementiert und produktionsbereit

## Projektübersicht

**Nevus** ist eine native iOS-App zur Erfassung, Katalogisierung und Überwachung von Leberflecken mit systematischen Vergleichsfunktionen und privatsphäre-orientierter Geräte-zu-Gerät-Synchronisation.

## Technologie-Stack

- **Plattform**: iOS 17.6+ (iPhone & iPad)
- **Sprache**: Swift 5.9+
- **UI Framework**: SwiftUI 5.0
- **Datenpersistenz**: SwiftData mit automatischem iCloud Backup
- **Kamera**: AVFoundation
- **Lokalisierung**: String Catalog (Deutsch, Englisch)
- **Sync**: AirDrop-basiert (.nevus Pakete)

**Nicht implementiert (geplant für Phase 2):**
- Core ML + Vision Framework
- CoreMotion (Sensordaten)
- Automatische Leberfleck-Erkennung

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

### 1. Datenmodell (SwiftData)

```swift
@Model
final class Mole {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var lastModified: Date
    var bodyRegion: String  // BodyRegion enum rawValue
    var bodySide: String    // BodySide enum rawValue
    var notes: String
    var referenceImageID: UUID?  // Für Overlay-Modus
    
    @Relationship(deleteRule: .cascade)
    var images: [MoleImage]
    
    @Relationship(deleteRule: .cascade)
    var locationMarkers: [MoleLocationMarker]
}

@Model
final class MoleImage {
    @Attribute(.unique) var id: UUID
    var captureDate: Date
    @Attribute(.externalStorage) var imageData: Data
    var thumbnailData: Data
    var imageWidth: Int
    var imageHeight: Int
    var mole: Mole?
}

@Model
final class BodyRegionOverview {
    @Attribute(.unique) var id: UUID
    var bodyRegion: String
    @Attribute(.externalStorage) var imageData: Data
    var thumbnailData: Data
    var captureDate: Date
    var notes: String
}

@Model
final class MoleLocationMarker {
    @Attribute(.unique) var id: UUID
    var x: Double  // 0.0 - 1.0
    var y: Double  // 0.0 - 1.0
    var mole: Mole?
    var overviewImage: BodyRegionOverview?
}

// Enums für Typsicherheit
enum BodyRegion: String, CaseIterable {
    case head, neck, armLeft, armRight
    case chest, abdomen, pelvis
    case backUpper, backMiddle, backLower
    case legLeft, legRight
}

enum BodySide: String, CaseIterable {
    // 26 region-spezifische Seiten
    case headTop, headFront, headLeft, headRight, headBack
    case neckFront, neckLeft, neckRight, neckBack
    case torsoLeft, torsoCenter, torsoRight
    case armUpperFront, armUpperBack, armLowerInner, armLowerOuter
    case handInner, handOuter
    case legThighFront, legThighBack, legThighInner, legThighOuter
    case legCalfFront, legCalfBack, legCalfInner, legCalfOuter
    case footTop, footSole
}
```

### 2. Service-Layer

#### CameraService (Implementiert)
**Datei:** `Services/CameraService.swift`
- Singleton-Pattern (`@MainActor`)
- AVCaptureSession Management
- Direkter Callback für schnelle Bilderfassung
- Autorisierungs-Handling
- Photo-Qualität: JPEG 90%
- Thumbnail-Generierung: 200x200, 70%

#### ExportService (Implementiert)
**Datei:** `Services/ExportService.swift`
- Export einzelner Leberfleck (ZIP mit JSON)
- Export aller Leberflecke (ZIP)
- Export einzelner Bilder (JPEG)
- Delta-Sync Export (.nevus Pakete)
- Automatische Dateinamen mit Zeitstempel

#### ImportService (Implementiert)
**Datei:** `Services/ImportService.swift`
- Import von .nevus Sync-Paketen
- UUID-basierte Duplikat-Erkennung
- Smart Merge (erhält bestehende Daten)
- Unzip und JSON-Parsing
- Fehlerbehandlung und Statistiken

#### GuidedScanningService (Implementiert)
**Datei:** `Services/GuidedScanningService.swift`
- Systematisches Fotografieren aller Leberflecke
- Fortschritts-Tracking
- Navigation (next, previous, skip)
- Session-Management

#### GuidedComparisonService (Implementiert)
**Datei:** `Services/GuidedComparisonService.swift`
- Systematischer Vergleich aller Leberflecke
- Filtert Leberflecke mit ≥2 Bildern
- Fortschritts-Tracking
- Vergleichs-Statistiken

#### NotificationService (Implementiert)
**Datei:** `Services/NotificationService.swift`
- Monatliche Erinnerungen
- Berechtigungs-Management
- Lokale Benachrichtigungen

#### CleanupService (Implementiert)
**Datei:** `Services/CleanupService.swift`
- Löschen alter Sessions
- Batch-Operationen
- Statistiken

**Nicht implementiert (geplant):**
- SensorService (CoreMotion)
- MLService (Core ML)

### 3. Bildvergleichs-System (Implementiert)

**Manuelle Auswahl statt automatischer Zuordnung:**

```
Benutzer wählt Leberfleck
    │
    ▼
┌─────────────────────────┐
│  Referenzbild-Auswahl   │
│  - Ältestes Bild oder   │
│  - Benutzer-definiert   │
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│  ComparisonView         │
│  - Side-by-Side         │
│  - Overlay mit Slider   │
│  - Zoom & Pan           │
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│  Benutzer-Bewertung     │
│  - Notizen hinzufügen   │
│  - Änderungen markieren │
└─────────────────────────┘
```

**Guided Comparison Workflow:**
1. System filtert Leberflecke mit ≥2 Bildern
2. Sortiert nach letzter Änderung (älteste zuerst)
3. Zeigt Referenzbild vs. neuestes Bild
4. Benutzer kann Notizen bearbeiten
5. Markiert als "verglichen" oder "übersprungen"
6. Statistiken am Ende

### 4. Sync-System (Implementiert)

**AirDrop-basierte Synchronisation:**

```
Quellgerät (iPhone)
    │
    ▼
┌─────────────────────────┐
│  Delta-Sync Export      │
│  - Datum auswählen      │
│  - Nur neue Daten       │
│  - .nevus ZIP erstellen │
└──────────┬──────────────┘
           │
           ▼ AirDrop
┌─────────────────────────┐
│  Zielgerät (iPad)       │
│  - Automatischer Import │
│  - Duplikat-Erkennung   │
│  - Smart Merge          │
└─────────────────────────┘
```

**Vorteile:**
- Keine Cloud-Abhängigkeit
- Vollständige Privatsphäre
- Schnelle lokale Übertragung
- UUID-basierte Duplikat-Erkennung

## UI-Struktur (Implementiert)

### Hauptansichten

1. **ContentView** (Hauptliste)
   - Gruppiert nach Körperregionen
   - Übersichtsbilder inline (horizontal scroll auf iPhone, Grid auf iPad)
   - Leberfleck-Liste mit Thumbnails
   - NavigationSplitView auf iPad (Master-Detail)
   - Export/Import/Sync Menü

2. **MoleDetailView**
   - Adaptive Bildergalerie (horizontal scroll auf iPhone, Grid auf iPad)
   - Bearbeitbare Felder (Region, Seite, Notizen)
   - Export-Menü (Leberfleck oder einzelnes Bild)
   - Direkter Zugriff auf Bildvergleich
   - Referenzbild-Auswahl

3. **CameraView**
   - Live-Kamera-Preview (AVCaptureVideoPreviewLayer)
   - Direkter Callback für schnelle Erfassung
   - Overlay-Modus mit Referenzbild
   - Autorisierungs-Handling

4. **ComparisonView**
   - Side-by-Side Modus
   - Overlay-Modus mit Transparenz-Slider
   - Pinch-to-Zoom und Pan
   - Swap-Funktion
   - Datumsanzeige für beide Bilder

5. **RegionOverviewView**
   - Übersichtsbilder pro Körperregion
   - Adaptive Grid (2 Spalten iPhone, 4 Spalten iPad)
   - Kamera-Integration
   - Notizen pro Bild

6. **AllRegionsOverviewView**
   - Alle Regionen mit Übersichtsbildern
   - Adaptive Grid (3 Spalten iPhone, 5 Spalten iPad)
   - Schnellzugriff auf alle Übersichten

7. **GuidedScanningView**
   - Systematisches Fotografieren
   - Fortschrittsanzeige
   - Overlay mit Referenzbild
   - Statistiken

8. **GuidedComparisonView**
   - Systematischer Vergleich
   - Embedded ComparisonView
   - Inline-Notizen-Bearbeitung
   - Statistiken

9. **SyncView**
   - Delta-Sync Export
   - Grafischer Datumswähler
   - Export-Vorschau mit Statistiken
   - Share Sheet Integration

10. **ImportConfirmationView**
    - Paket-Vorschau
    - Import-Statistiken
    - Fehlerbehandlung
    - Ergebnis-Anzeige

## Datenschutz und Sicherheit (Implementiert)

### Lokale Speicherung
- Alle Bilder in App-Container (SwiftData)
- External Storage für große Bilddaten
- Keine Weitergabe an Dritte
- Automatisches iCloud Backup (opt-in durch Benutzer)

### AirDrop-Sync
- Lokale Übertragung ohne Cloud
- Verschlüsselt durch AirDrop
- Keine Tracking oder Analytics
- Vollständige Benutzerkontrolle

### Berechtigungen
- **Kamera-Zugriff** (erforderlich) - NSCameraUsageDescription
- **Benachrichtigungen** (optional) - Monatliche Erinnerungen
- **Dateien** (automatisch) - .nevus Import/Export

**Nicht verwendet:**
- Standort (keine GPS-Daten)
- Bewegungssensoren (noch nicht implementiert)
- Foto-Bibliothek (direkter Export via Share Sheet)

## Performance-Optimierungen (Implementiert)

1. **Bildverarbeitung**
   - Asynchrone Verarbeitung mit async/await
   - Thumbnail-Generierung (200x200, 70% JPEG)
   - External Storage für große Bilddaten
   - Lazy Loading in Grids
   - Direkter Kamera-Callback (9s Verzögerung behoben)

2. **Datenbank**
   - SwiftData mit automatischer Optimierung
   - @Attribute(.unique) für schnelle Lookups
   - Cascade Delete für Beziehungen
   - Automatisches iCloud Backup

3. **UI-Performance**
   - LazyVGrid/LazyHGrid für effizientes Rendering
   - Adaptive Layouts basierend auf Size Class
   - Thumbnail-Caching durch SwiftData

## Implementierungsstatus

### ✅ Phase 1 (Abgeschlossen)
- Grundlegende Erfassung und Katalogisierung
- 12 Körperregionen, 26 Körperseiten
- Bildvergleich (Side-by-Side & Overlay)
- Export/Import Funktionalität
- Übersichtsbilder pro Region
- Guided Scanning & Comparison
- AirDrop Sync
- iPad-Optimierung
- Internationalisierung (DE/EN)
- Monatliche Erinnerungen

### 🔄 Phase 2 (Geplant)
- Core ML Integration
- Automatische Leberfleck-Erkennung
- Sensordaten (CoreMotion)
- Automatische Zuordnung
- Änderungs-Detektion mit ML
- PDF-Export für Ärzte

### 📋 Phase 3 (Geplant)
- Apple Watch Companion App
- HealthKit-Integration
- Erweiterte Statistiken
- Teilen mit Dermatologen

### 🔮 Phase 4 (Vision)
- AR-basierte Körperkarte
- 3D-Scanning
- Telemedicine-Integration
- KI-gestützte Früherkennung

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