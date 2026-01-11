# MoleTracker - iOS App für Leberfleck-Überwachung

Eine native iOS-App zur systematischen Erfassung, Katalogisierung und Überwachung von Leberflecken mit automatischer Zuordnung durch Sensordaten und Machine Learning.

## 🎯 Projektziel

MoleTracker ermöglicht es Benutzern, Leberflecke am Körper zu fotografieren, zu katalogisieren und über die Zeit zu vergleichen. Die App nutzt iPhone-Sensoren (Neigungswinkel, Barometer) und Machine Learning, um Aufnahmen automatisch den richtigen Leberflecken zuzuordnen.

## ✨ Hauptfunktionen

### Phase 1 (MVP)
- 📸 **Hochauflösende Bildaufnahme** mit Kamera-Integration
- 📊 **Sensor-Daten-Erfassung** (Neigung, Barometer)
- 🗂️ **Katalogisierung** von Leberflecken mit Körperkarte
- 🔍 **Bildvergleich** (Side-by-Side und Overlay) mit datumsbasierter Auswahl
- ☁️ **iCloud-Synchronisation** für Backup
- 🔒 **Lokale Datenspeicherung** mit Verschlüsselung

### Phase 2
- 🤖 **Core ML Integration** für automatische Erkennung
- 🎯 **Automatische Zuordnung** basierend auf Sensoren + ML
- 📈 **Änderungs-Tracking** mit Verlaufsanzeige
- 📄 **PDF-Export** für Arztbesuche

### Phase 3+
- ⌚ **Apple Watch App** für Erinnerungen
- 🏥 **HealthKit-Integration**
- 👨‍⚕️ **Dermatologen-Portal** zum Teilen
- 🧠 **Erweiterte ML-Modelle** für Risiko-Einschätzung

## 🏗️ Technologie-Stack

- **Plattform**: iOS 16+
- **Sprache**: Swift 5.9+
- **UI**: SwiftUI
- **Datenpersistenz**: SwiftData (mit Core Data Fallback)
- **Cloud**: CloudKit
- **ML**: Core ML + Vision Framework
- **Sensoren**: CoreMotion, AVFoundation

## 📁 Projekt-Struktur

```
MoleTracker/
├── App/
│   ├── MoleTrackerApp.swift          # App Entry Point
│   └── AppDelegate.swift             # App Lifecycle
├── Models/
│   ├── Mole.swift                    # Leberfleck-Datenmodell
│   ├── MoleImage.swift               # Bild mit Metadaten
│   ├── BodyLocation.swift            # Körperposition
│   └── SensorData.swift              # Sensor-Daten
├── ViewModels/
│   ├── CameraViewModel.swift         # Kamera-Logik
│   ├── MoleListViewModel.swift       # Listen-Verwaltung
│   ├── MoleDetailViewModel.swift     # Detail-Ansicht
│   └── BodyMapViewModel.swift        # Körperkarte
├── Views/
│   ├── Home/                         # Dashboard
│   ├── Camera/                       # Kamera-Aufnahme
│   ├── MoleList/                     # Leberfleck-Liste
│   ├── MoleDetail/                   # Detail-Ansicht
│   ├── BodyMap/                      # Interaktive Körperkarte
│   └── Comparison/                   # Bildvergleich
├── Services/
│   ├── CameraService.swift           # Kamera-Service
│   ├── SensorService.swift           # Sensor-Integration
│   ├── MLService.swift               # ML-Verarbeitung
│   ├── StorageService.swift          # Daten-Persistenz
│   └── CloudSyncService.swift        # iCloud-Sync
├── Utilities/
│   ├── Extensions/                   # Swift-Extensions
│   ├── Constants.swift               # App-Konstanten
│   └── Helpers.swift                 # Helper-Funktionen
└── Resources/
    ├── Assets.xcassets               # Bilder & Icons
    └── Localizable.strings           # Übersetzungen
```

## 🚀 Entwicklungs-Roadmap

### Woche 1-2: Projekt-Setup
- [x] Architektur-Planung
- [x] Projekt-Plan erstellen
- [x] Technische Spezifikationen
- [ ] Xcode-Projekt anlegen
- [ ] Grundstruktur aufbauen

### Woche 2-3: Datenmodell
- [ ] SwiftData-Modelle implementieren
- [ ] StorageService erstellen
- [ ] CloudKit-Setup
- [ ] Unit Tests für Models

### Woche 3-4: Kamera-Integration
- [ ] CameraService implementieren
- [ ] Bildaufnahme mit Preview
- [ ] Bildkompression
- [ ] Thumbnail-Generierung

### Woche 4-5: Sensor-Integration
- [ ] SensorService implementieren
- [ ] CoreMotion-Integration
- [ ] Barometer-Daten
- [ ] Körperregion-Mapping

### Woche 5-7: Machine Learning
- [ ] ML-Modell vorbereiten
- [ ] MLService implementieren
- [ ] Feature-Extraktion
- [ ] Vision Framework Integration

### Woche 7-8: Matching-Algorithmus
- [ ] Multi-Faktor-Matching
- [ ] Sensor-Similarity
- [ ] Feature-Similarity
- [ ] Confidence-Scoring

### Woche 8-11: UI-Implementierung
- [ ] HomeView
- [ ] BodyMapView
- [ ] CameraView
- [ ] MoleListView
- [ ] MoleDetailView
- [ ] ComparisonView

### Woche 11-12: iCloud-Sync
- [ ] CloudKit-Integration
- [ ] Sync-Service
- [ ] Konfliktauflösung
- [ ] Offline-Modus

### Woche 12-14: Testing
- [ ] Unit Tests
- [ ] UI Tests
- [ ] Integration Tests
- [ ] Beta-Testing (TestFlight)

### Woche 14-16: Launch
- [ ] UI/UX-Polishing
- [ ] Performance-Optimierung
- [ ] App Store Vorbereitung
- [ ] Launch

## 📊 Architektur-Übersicht

### MVVM-Pattern

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

### Matching-Algorithmus

Der Algorithmus kombiniert drei Faktoren für die automatische Zuordnung:

1. **Sensor-basiertes Matching (45%)**
   - Geräteneigung → Körperregion
   - Barometer → Vertikale Position

2. **ML-Feature-Matching (55%)**
   - Cosine-Similarity der Feature-Vektoren
   - Größe und Form
   - Farbprofil

**Hinweis**: Für Bildvergleiche wählt der Benutzer manuell aus vorherigen Aufnahmen basierend auf dem Aufnahmedatum.

**Confidence-Schwellwerte:**
- \> 0.85: Automatische Zuordnung
- 0.70-0.85: Vorschlag mit Bestätigung
- < 0.70: Manuelle Auswahl

## 🔒 Datenschutz und Sicherheit

### Lokale Speicherung
- ✅ Alle Bilder verschlüsselt im App-Container
- ✅ Keine Weitergabe an Dritte
- ✅ Biometrische Authentifizierung (Face ID/Touch ID)
- ✅ Kein Tracking oder Analytics ohne Zustimmung

### iCloud-Sync
- ✅ End-to-End-Verschlüsselung via CloudKit
- ✅ Opt-in für Cloud-Backup
- ✅ Automatische Konfliktauflösung
- ✅ Nur private CloudKit-Datenbank

### Berechtigungen
- 📸 Kamera-Zugriff (erforderlich)
- 📷 Foto-Bibliothek (optional, für Export)
- 🏃 Bewegungs- und Fitness-Daten (CoreMotion)

## 🎨 UI/UX-Konzept

### Design-Prinzipien
- **Einfachheit**: Intuitive Bedienung ohne Einarbeitung
- **Klarheit**: Klare Visualisierung von Änderungen
- **Vertrauen**: Transparente Datenverarbeitung
- **Geschwindigkeit**: Schnelle Erfassung und Vergleich

### Hauptansichten

1. **HomeView**: Dashboard mit Statistiken und letzten Aufnahmen
2. **BodyMapView**: Interaktive 2D-Körperkarte mit Mole-Markern
3. **CameraView**: Live-Preview mit Sensor-Feedback
4. **MoleDetailView**: Bildergalerie mit Timeline und datumsbasierter Vergleichsauswahl
5. **ComparisonView**: Side-by-Side und Overlay-Vergleich mit Datumsanzeige

## 📱 System-Anforderungen

### Minimum
- iOS 16.0+
- iPhone 12 oder neuer
- 500 MB freier Speicher
- Kamera mit Dual-System

### Empfohlen
- iOS 17.0+
- iPhone 14 Pro oder neuer
- 2 GB freier Speicher
- iCloud-Konto für Sync

## 🧪 Testing-Strategie

### Unit Tests
- Datenmodelle
- Services (Camera, Sensor, ML, Storage)
- Matching-Algorithmus
- Utilities

### UI Tests
- Navigation-Flow
- Kamera-Funktionalität
- Bildvergleich
- Daten-Persistenz

### Integration Tests
- End-to-End-Workflows
- CloudKit-Sync
- ML-Pipeline
- Performance

### Beta-Testing
- TestFlight-Distribution
- Feedback-Sammlung
- Bug-Fixes
- Performance-Optimierung

## 📈 Performance-Ziele

| Operation | Target | Maximum |
|-----------|--------|---------|
| App Launch | < 2s | < 3s |
| Foto-Aufnahme | < 1s | < 2s |
| ML-Inferenz | < 500ms | < 1s |
| Bildvergleich | < 500ms | < 1s |
| CloudKit-Sync | < 5s | < 10s |

## 🌍 Lokalisierung

### Phase 1
- 🇩🇪 Deutsch
- 🇬🇧 Englisch

### Phase 2+
- 🇫🇷 Französisch
- 🇪🇸 Spanisch
- 🇮🇹 Italienisch

## 📚 Dokumentation

- [`ARCHITECTURE.md`](ARCHITECTURE.md) - Detaillierte Architektur-Beschreibung
- [`PROJECT_PLAN.md`](PROJECT_PLAN.md) - Vollständiger Entwicklungsplan
- [`TECHNICAL_SPECIFICATIONS.md`](TECHNICAL_SPECIFICATIONS.md) - Technische Spezifikationen

## 🤝 Entwicklungs-Workflow

1. **Design**: Figma-Prototypen
2. **Implementation**: Feature-Branches
3. **Testing**: Unit + UI Tests
4. **Review**: Code Review
5. **Deploy**: TestFlight → App Store

## 📝 Lizenz

Dieses Projekt ist für den persönlichen Gebrauch bestimmt.

## 🔮 Zukünftige Erweiterungen

### Phase 2
- Apple Watch Companion App
- HealthKit-Integration
- PDF-Export für Ärzte
- Erweiterte Statistiken

### Phase 3
- iPad-Optimierung
- Familien-Sharing
- Dermatologen-Portal
- Risiko-Analyse mit ML

### Phase 4
- AR-basierte Körperkarte
- 3D-Scanning
- Telemedicine-Integration
- KI-gestützte Früherkennung

## 📞 Kontakt

Für Fragen oder Feedback zum Projekt, bitte ein Issue erstellen.

---

**Status**: 🏗️ In Planung
**Version**: 0.1.0 (Planning Phase)
**Letzte Aktualisierung**: Januar 2026