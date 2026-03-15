# Nevus - iOS App für Nevus-Überwachung

**Status:** ✅ Produktionsbereit - Version 1.0
**Letzte Aktualisierung:** 15. März 2026

Eine native iOS-App zur systematischen Erfassung, Katalogisierung und Überwachung von Leberflecken mit fortgeschrittenen Vergleichsfunktionen und privatsphäre-orientierter Geräte-zu-Gerät-Synchronisation.

## 🎯 Projektziel

Nevus ermöglicht es Benutzern, Leberflecke am Körper zu fotografieren, zu katalogisieren und über die Zeit zu vergleichen. Die App bietet systematische Workflows für regelmäßige Kontrollen und sichere Synchronisation zwischen Geräten ohne Cloud-Abhängigkeit.

## ✨ Hauptfunktionen

### ✅ Implementiert (Version 1.0)
- 📸 **Hochauflösende Bildaufnahme** - AVFoundation mit direktem Callback
- 🗂️ **12 Körperregionen, 26 Körperseiten** - Detaillierte Katalogisierung
- 🔍 **Bildvergleich** - Side-by-Side und Overlay mit Zoom
- 📊 **Übersichtsbilder** - Pro Körperregion mit Notizen
- 🎯 **Guided Scanning** - Systematisches Fotografieren aller Leberflecke
- 🔄 **Guided Comparison** - Systematischer Vergleich mit Referenzbildern
- 📤 **Export/Import** - ZIP-Export und AirDrop-Sync zwischen Geräten
- 💾 **SwiftData** - Lokale Speicherung mit automatischem iCloud Backup
- 📱 **iPad-Optimierung** - Master-Detail Layout und adaptive Grids
- 🌍 **Internationalisierung** - Deutsch und Englisch
- 🔔 **Monatliche Erinnerungen** - Für regelmäßige Kontrollen
- 🔒 **Privatsphäre** - Keine Cloud-Abhängigkeit, lokale Daten

### 🔄 Geplant (Phase 2)
- 🤖 **Core ML Integration** für automatische Erkennung
- 📊 **Sensordaten** (CoreMotion) für Geräteneigung
- 🎯 **Automatische Zuordnung** basierend auf Sensoren + ML
- 📈 **Änderungs-Detektion** mit ML
- 📄 **PDF-Export** für Arztbesuche

### 📋 Geplant (Phase 3+)
- ⌚ **Apple Watch App** für Erinnerungen
- 🏥 **HealthKit-Integration**
- 👨‍⚕️ **Dermatologen-Portal** zum Teilen
- 🧠 **Erweiterte ML-Modelle** für Risiko-Einschätzung

## 🏗️ Technologie-Stack

- **Plattform**: iOS 17.6+ (iPhone & iPad)
- **Sprache**: Swift 5.9+
- **UI**: SwiftUI 5.0
- **Datenpersistenz**: SwiftData mit automatischem iCloud Backup
- **Kamera**: AVFoundation
- **Lokalisierung**: String Catalog (DE/EN)
- **Sync**: AirDrop-basiert (.nevus Pakete)

**Geplant für Phase 2:**
- Core ML + Vision Framework
- CoreMotion (Sensordaten)

## 📁 Projekt-Struktur

```
Nevus/
├── App/
│   ├── NevusApp.swift          # App Entry Point
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

## 🚀 Entwicklungsstatus

### ✅ Phase 1 - Abgeschlossen (Januar - März 2026)
- [x] Architektur-Planung und Spezifikationen
- [x] Xcode-Projekt und Grundstruktur
- [x] SwiftData-Modelle (Mole, MoleImage, BodyRegionOverview, MoleLocationMarker)
- [x] CameraService mit AVFoundation
- [x] Kamera-Integration mit Overlay-Modus
- [x] Bildkompression und Thumbnail-Generierung
- [x] UI-Implementierung (10+ Views)
- [x] Bildvergleich (Side-by-Side & Overlay)
- [x] Übersichtsbilder pro Körperregion
- [x] Guided Scanning & Comparison
- [x] Export/Import Funktionalität
- [x] AirDrop-Sync zwischen Geräten
- [x] iPad-Optimierung mit adaptiven Layouts
- [x] Internationalisierung (DE/EN)
- [x] Monatliche Erinnerungen
- [x] Session Cleanup
- [x] Dokumentation

### 🔄 Phase 2 - Geplant
- [ ] CoreMotion-Integration für Sensordaten
- [ ] Core ML Modell-Integration
- [ ] Automatische Leberfleck-Erkennung
- [ ] ML-basierte Änderungs-Detektion
- [ ] PDF-Export für Ärzte
- [ ] Erweiterte Statistiken

### 📋 Phase 3 - Geplant
- [ ] Apple Watch Companion App
- [ ] HealthKit-Integration
- [ ] Dermatologen-Portal
- [ ] Familien-Sharing

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

### Bildvergleichs-System

**Aktuell implementiert:**
- Manuelle Auswahl von Bildern für Vergleich
- Referenzbild-System (ältestes oder benutzer-definiert)
- Side-by-Side und Overlay-Vergleich
- Guided Comparison für systematische Durchsicht

**Geplant für Phase 2:**
- Automatische Zuordnung mit ML
- Sensor-basiertes Matching (CoreMotion)
- ML-Feature-Matching (Core ML)
- Confidence-Scoring für Vorschläge

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
- iOS 17.6+
- iPhone oder iPad
- 500 MB freier Speicher
- Rückkamera

### Empfohlen
- iOS 17.6+
- iPhone 14 Pro oder neuer, iPad Pro
- 2 GB freier Speicher
- iCloud-Konto für automatisches Backup

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

### Hauptdokumentation
- [`README.md`](README.md) - Projektübersicht (dieses Dokument)
- [`ARCHITECTURE.md`](Documentation/ARCHITECTURE.md) - Systemarchitektur
- [`TECHNICAL_SPECIFICATIONS.md`](Documentation/TECHNICAL_SPECIFICATIONS.md) - Technische Spezifikationen
- [`IMPLEMENTATION_SUMMARY.md`](Documentation/IMPLEMENTATION_SUMMARY.md) - Implementierungszusammenfassung
- [`INTERNATIONALIZATION.md`](Documentation/INTERNATIONALIZATION.md) - Lokalisierung
- [`IPAD_COMPATIBILITY.md`](Documentation/IPAD_COMPATIBILITY.md) - iPad-Unterstützung

### Feature-Dokumentation
- [Guided Scanning](Documentation/Features/GUIDED_SCANNING_FEATURE.md)
- [Guided Comparison](Documentation/Features/GUIDED_COMPARISON_FEATURE.md)
- [AirDrop Sync](Documentation/Features/AIRDROP_SYNC_IMPLEMENTATION_COMPLETE.md)
- [Region Overview](Documentation/Features/REGION_OVERVIEW_FEATURE.md)
- [Und weitere...](Documentation/Features/)

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

**Status**: ✅ Produktionsbereit - Version 1.0
**Letzte Aktualisierung**: 15. März 2026

**Implementierte Features:**
- ✅ Core Funktionalität (12 Regionen, 26 Seiten)
- ✅ Bildvergleich (Side-by-Side & Overlay)
- ✅ Übersichtsbilder pro Region
- ✅ Guided Scanning & Comparison
- ✅ AirDrop Sync zwischen Geräten
- ✅ iPad-Optimierung
- ✅ Internationalisierung (DE/EN)
- ✅ Export/Import Funktionalität

**Geplant für Phase 2:**
- 🔄 Core ML Integration
- 🔄 Sensordaten (CoreMotion)
- 🔄 Automatische Zuordnung
- 🔄 PDF-Export für Ärzte