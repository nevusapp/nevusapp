# Körperregion-Übersichtsbilder Feature

## Übersicht
Die App unterstützt jetzt Übersichtsbilder für jede Körperregion, in denen alle Leberflecke der Region gleichzeitig sichtbar sind. Dies ermöglicht eine bessere Gesamtübersicht und erleichtert das Auffinden von Veränderungen.

## Implementierung

### 1. Datenmodell: BodyRegionOverview

**Datei:** `MoleTracker/Models/BodyRegionOverview.swift`

**Eigenschaften:**
- `id: UUID` - Eindeutige ID
- `bodyRegion: String` - Körperregion (z.B. "Kopf", "Arme/Hände")
- `captureDate: Date` - Aufnahmedatum
- `notes: String` - Bearbeitbare Notizen
- `imageData: Data?` - Bilddaten (external storage)
- Sensordaten: `pitch`, `roll`, `yaw`, `barometricPressure`, `altitude`

**Methoden:**
- `init(bodyRegion:image:)` - Erstellt Übersichtsbild mit UIImage
- `uiImage` - Gibt UIImage zurück
- `thumbnailImage` - Gibt Thumbnail (200x200) zurück
- `updateSensorData(...)` - Aktualisiert Sensordaten

### 2. View: RegionOverviewView

**Datei:** `MoleTracker/Views/RegionOverviewView.swift`

**Funktionen:**
- Zeigt alle Übersichtsbilder einer Körperregion
- Grid-Layout mit 2 Spalten
- Kamera-Button zum Aufnehmen neuer Übersichtsbilder
- Tap auf Bild öffnet Detailansicht
- Context-Menü zum Löschen
- Empty State wenn keine Bilder vorhanden

**Query-Filter:**
```swift
Query(
    filter: #Predicate<BodyRegionOverview> { overview in
        overview.bodyRegion == regionName
    },
    sort: \BodyRegionOverview.captureDate,
    order: .reverse
)
```

### 3. Detail View: OverviewImageDetailView

**Funktionen:**
- Vollbild-Ansicht mit Zoom (Pinch-Gesture)
- Anzeige von Aufnahmedatum
- Bearbeitbare Notizen
- "Bearbeiten"/"Fertig" Button in Toolbar

### 4. Integration in ContentView

**Änderungen:**
- Jede Körperregion-Sektion hat jetzt einen "Übersichtsbilder" Button
- Button mit Icon `photo.on.rectangle.angled`
- NavigationLink zu `RegionOverviewView`
- Erscheint über den individuellen Leberflecken

## Benutzerführung

### Übersichtsbilder aufnehmen

1. **Hauptansicht öffnen**
   - App starten → Liste der Körperregionen

2. **Region auswählen**
   - Auf "Übersichtsbilder" Button in gewünschter Region tippen

3. **Foto aufnehmen**
   - Kamera-Symbol (oben rechts) antippen
   - Körperregion so fotografieren, dass alle Leberflecke sichtbar sind
   - Foto wird automatisch gespeichert

4. **Notizen hinzufügen (optional)**
   - Auf Übersichtsbild tippen
   - "Bearbeiten" antippen
   - Notizen eingeben
   - "Fertig" antippen

### Übersichtsbilder verwalten

**Ansehen:**
- Tap auf Thumbnail öffnet Vollbild-Ansicht
- Pinch-to-Zoom für Details

**Löschen:**
- Long-Press auf Thumbnail
- "Löschen" im Context-Menü wählen

**Sortierung:**
- Neueste Bilder zuerst
- Chronologische Reihenfolge

## Technische Details

### Datenspeicherung
- **SwiftData Model** mit `@Model` Annotation
- **External Storage** für Bilddaten (`@Attribute(.externalStorage)`)
- **Automatisches iCloud Backup** (wenn aktiviert)
- **JPEG Kompression** mit 80% Qualität

### Sensordaten
- Automatische Erfassung beim Fotografieren
- Pitch, Roll, Yaw von Geräteneigung
- Barometrischer Druck (optional)
- Höhe über Meeresspiegel (optional)
- Daten von `CameraService.shared`

### Performance
- **Thumbnails** (200x200) für Grid-Ansicht
- **Lazy Loading** mit LazyVGrid
- **Async Image Processing** für responsive UI

## UI/UX Design

### Grid-Layout
```swift
LazyVGrid(columns: [
    GridItem(.flexible(), spacing: 12),
    GridItem(.flexible(), spacing: 12)
], spacing: 12)
```

### Empty State
- Icon: `photo.on.rectangle.angled` (60pt)
- Titel: "Keine Übersichtsbilder"
- Beschreibung: Anleitung zum Aufnehmen
- Padding: 40pt vertikal

### Farben
- Accent Color für "Übersichtsbilder" Button
- System Gray für Platzhalter
- Ultra Thin Material für Info-Bereiche

## Anwendungsfälle

### 1. Erstdokumentation
- Übersichtsbild jeder Körperregion aufnehmen
- Alle Leberflecke auf einen Blick
- Referenz für zukünftige Vergleiche

### 2. Regelmäßige Kontrolle
- Neue Übersichtsbilder in regelmäßigen Abständen
- Vergleich mit früheren Aufnahmen
- Erkennung neuer Leberflecke

### 3. Arztbesuch
- Übersichtsbilder zeigen Gesamtsituation
- Einzelne Leberflecke können dann detailliert betrachtet werden
- Vollständige Dokumentation

### 4. Selbstuntersuchung
- Systematische Kontrolle aller Körperregionen
- Notizen zu Auffälligkeiten
- Zeitliche Entwicklung nachvollziehbar

## Vorteile

### Für Benutzer
✅ **Gesamtübersicht** - Alle Leberflecke einer Region auf einen Blick
✅ **Einfache Navigation** - Direkt von Hauptansicht erreichbar
✅ **Zeitersparnis** - Schneller Überblick ohne einzelne Leberflecke öffnen
✅ **Vergleichbarkeit** - Mehrere Übersichtsbilder über Zeit
✅ **Flexibilität** - Notizen für jedes Übersichtsbild

### Für Ärzte
✅ **Kontext** - Lage der Leberflecke im Gesamtbild
✅ **Vollständigkeit** - Keine Leberflecke übersehen
✅ **Dokumentation** - Professionelle Bilderfassung
✅ **Verlaufskontrolle** - Entwicklung über Zeit

## Datenschutz

- **Lokale Speicherung** - Alle Daten bleiben auf dem Gerät
- **iCloud Backup** - Optional, vom Benutzer kontrolliert
- **Keine Cloud-Sync** - Keine automatische Übertragung
- **Keine Metadaten** - Keine GPS-Koordinaten in Bildern

## Zukünftige Erweiterungen

### Mögliche Features
- [ ] Automatische Leberfleck-Erkennung in Übersichtsbildern
- [ ] Markierung einzelner Leberflecke im Übersichtsbild
- [ ] Verknüpfung Übersichtsbild ↔ Einzelaufnahmen
- [ ] Side-by-Side Vergleich von Übersichtsbildern
- [ ] Export von Übersichtsbildern
- [ ] Annotationen/Zeichnungen auf Übersichtsbildern

## Datum
Implementiert: 11. Januar 2026