# Referenzbild-Auswahl für Overlay-Modus

## Übersicht
Benutzer können jetzt ein spezifisches Bild als Referenz für den Overlay-Modus auswählen. Standardmäßig wird das älteste Bild (erste Aufnahme) verwendet, um langfristige Vergleichbarkeit zu gewährleisten.

## Implementierung

### 1. Datenmodell-Erweiterung

**Datei:** `MoleTracker/Models/Mole.swift`

**Neue Eigenschaften:**
```swift
// Reference image ID for overlay mode (defaults to oldest image)
var referenceImageID: UUID?
```

**Neue Computed Property:**
```swift
var referenceImage: MoleImage? {
    // If a specific reference is set, use it
    if let refID = referenceImageID,
       let image = images.first(where: { $0.id == refID }) {
        return image
    }
    
    // Otherwise, default to the oldest image (first captured)
    return images.sorted(by: { $0.captureDate < $1.captureDate }).first
}
```

**Neue Methoden:**
```swift
// Set a specific image as reference for overlay
func setReferenceImage(_ image: MoleImage) {
    self.referenceImageID = image.id
    updateModifiedDate()
}

// Clear reference image (will default to oldest)
func clearReferenceImage() {
    self.referenceImageID = nil
    updateModifiedDate()
}
```

### 2. UI-Komponenten

#### A) Overlay-Einstellungen Sektion (MoleDetailView)

**Neue Sektion in der Detailansicht:**
```swift
Section {
    // Aktuelles Referenzbild anzeigen
    if let refImage = mole.referenceImage {
        HStack {
            // Thumbnail
            if let thumbnail = refImage.thumbnailImage {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text("Referenzbild für Overlay")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(refImage.captureDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Reset-Button (nur wenn manuell gesetzt)
            if mole.referenceImageID != nil {
                Button("Zurücksetzen") {
                    mole.clearReferenceImage()
                }
                .font(.caption)
            }
        }
    }
    
    // Link zur Auswahl-View
    if mole.images.count >= 2 {
        NavigationLink(destination: ReferenceImageSelectionView(mole: mole)) {
            Label("Referenzbild ändern", systemImage: "photo.on.rectangle.angled")
        }
    }
} header: {
    Text("Overlay-Einstellungen")
} footer: {
    Text("Das Referenzbild wird beim Fotografieren als halbtransparentes Overlay angezeigt. Standard: Ältestes Bild (erste Aufnahme).")
        .font(.caption)
}
```

#### B) Stern-Indikator im Bilder-Grid

**Visueller Indikator für Referenzbild:**
```swift
// Reference image indicator
if mole.referenceImage?.id == image.id {
    Image(systemName: "star.fill")
        .font(.caption)
        .foregroundColor(.yellow)
        .padding(4)
        .background(Color.black.opacity(0.6))
        .clipShape(Circle())
        .padding(4)
}
```

#### C) Referenzbild-Auswahl View

**Neue View:** `ReferenceImageSelectionView`

```swift
struct ReferenceImageSelectionView: View {
    @Bindable var mole: Mole
    @Environment(\.dismiss) private var dismiss
    
    var sortedImages: [MoleImage] {
        mole.images.sorted(by: { $0.captureDate < $1.captureDate }) // Oldest first
    }
    
    var body: some View {
        List {
            Section {
                ForEach(sortedImages) { image in
                    Button(action: {
                        mole.setReferenceImage(image)
                        dismiss()
                    }) {
                        HStack(spacing: 12) {
                            // Thumbnail (80x80)
                            // Info (Datum, "Erste Aufnahme", Auflösung)
                            // Checkmark wenn ausgewählt
                        }
                    }
                }
            } header: {
                Text("Wähle ein Referenzbild")
            } footer: {
                Text("Das ausgewählte Bild wird beim Fotografieren als halbtransparentes Overlay angezeigt. Die erste Aufnahme ist standardmäßig ausgewählt für langfristige Vergleichbarkeit.")
            }
        }
        .navigationTitle("Referenzbild")
    }
}
```

### 3. Integration mit CameraView

**Automatische Verwendung des Referenzbilds:**
```swift
.sheet(isPresented: $showingCamera) {
    CameraView(referenceImage: mole.referenceImage?.uiImage) { image in
        addImage(image)
    }
}
```

## Benutzerführung

### Standard-Verhalten (ohne manuelle Auswahl)

1. **Erste Aufnahme**
   - Kein Overlay (kein vorheriges Bild vorhanden)
   - Bild wird als Referenz gespeichert

2. **Zweite Aufnahme**
   - Overlay zeigt automatisch die erste Aufnahme
   - Langfristige Vergleichbarkeit gewährleistet

3. **Weitere Aufnahmen**
   - Overlay zeigt weiterhin die erste Aufnahme
   - Konsistente Referenz über die Zeit

### Manuelle Referenzbild-Auswahl

#### Option 1: Aus Overlay-Einstellungen

1. **Leberfleck-Detailansicht öffnen**
2. **Sektion "Overlay-Einstellungen" finden**
3. **"Referenzbild ändern" antippen**
4. **Gewünschtes Bild auswählen**
   - Liste zeigt alle Bilder chronologisch (älteste zuerst)
   - Aktuelles Referenzbild ist mit Checkmark markiert
   - "Erste Aufnahme (Standard)" ist gekennzeichnet
5. **Bild antippen** → Automatische Auswahl und Rückkehr

#### Option 2: Zurücksetzen auf Standard

1. **Overlay-Einstellungen öffnen**
2. **"Zurücksetzen" Button antippen**
   - Nur sichtbar wenn manuell geändert
   - Setzt zurück auf ältestes Bild

### Visuelle Indikatoren

**Im Bilder-Grid:**
- ⭐ **Gelber Stern** oben links = Aktuelles Referenzbild
- Alle anderen Bilder ohne Stern

**In Overlay-Einstellungen:**
- 📷 **Thumbnail** des aktuellen Referenzbilds
- 📅 **Datum** der Aufnahme
- 🔄 **"Zurücksetzen"** Button (wenn manuell geändert)

**In Auswahl-View:**
- ✅ **Checkmark** beim aktuellen Referenzbild
- 🏷️ **"Erste Aufnahme (Standard)"** Label
- 📐 **Auflösung** jedes Bildes

## Anwendungsfälle

### Use Case 1: Langfristige Verlaufskontrolle
**Szenario:** Leberfleck über Jahre beobachten

**Lösung:**
- Standard-Verhalten nutzen (erste Aufnahme)
- Alle Folgeaufnahmen vergleichen mit Ausgangszustand
- Langfristige Veränderungen erkennbar

### Use Case 2: Kurzfristige Veränderung dokumentieren
**Szenario:** Leberfleck hat sich verändert, neue Baseline setzen

**Lösung:**
1. Aktuelles Bild als neues Referenzbild wählen
2. Zukünftige Aufnahmen vergleichen mit neuem Zustand
3. Bei Bedarf zurück zur ersten Aufnahme wechseln

### Use Case 3: Beste Aufnahme als Referenz
**Szenario:** Eine Aufnahme ist besonders gut (Beleuchtung, Schärfe)

**Lösung:**
1. Beste Aufnahme als Referenzbild auswählen
2. Alle Folgeaufnahmen orientieren sich daran
3. Konsistente Qualität der Aufnahmen

### Use Case 4: Vergleich mit spezifischem Zeitpunkt
**Szenario:** Vergleich mit Zustand vor 6 Monaten

**Lösung:**
1. Bild von vor 6 Monaten als Referenz wählen
2. Neue Aufnahme mit Overlay machen
3. Direkte Vergleichbarkeit mit gewünschtem Zeitpunkt

## Vorteile

### Für Benutzer
✅ **Flexibilität** - Freie Wahl des Referenzbilds
✅ **Langfristige Vergleichbarkeit** - Standard auf erste Aufnahme
✅ **Einfache Bedienung** - Ein Tap zur Auswahl
✅ **Visuelle Klarheit** - Stern-Indikator zeigt Referenz
✅ **Reversibilität** - Zurücksetzen jederzeit möglich

### Für medizinische Dokumentation
✅ **Standardisierung** - Konsistente Referenz über Zeit
✅ **Flexibilität** - Anpassung bei Veränderungen
✅ **Nachvollziehbarkeit** - Referenzbild ist dokumentiert
✅ **Qualitätssicherung** - Beste Aufnahme als Referenz wählbar

## Technische Details

### Datenpersistenz
- **SwiftData**: Automatische Speicherung der `referenceImageID`
- **iCloud Sync**: Referenzbild-Auswahl wird synchronisiert
- **Cascade Delete**: Bei Löschen des Referenzbilds → Automatisch auf Standard zurück

### Performance
- **Lazy Loading**: Nur Thumbnail in Liste geladen
- **Efficient Sorting**: Sortierung nur bei Bedarf
- **Minimal Updates**: Nur bei Änderung der Auswahl

### Edge Cases

**Fall 1: Referenzbild wird gelöscht**
```swift
var referenceImage: MoleImage? {
    if let refID = referenceImageID,
       let image = images.first(where: { $0.id == refID }) {
        return image  // Gefunden
    }
    // Nicht gefunden → Fallback auf ältestes
    return images.sorted(by: { $0.captureDate < $1.captureDate }).first
}
```

**Fall 2: Alle Bilder gelöscht**
- `referenceImage` gibt `nil` zurück
- CameraView zeigt kein Overlay
- Nächste Aufnahme wird neue Referenz

**Fall 3: Nur ein Bild vorhanden**
- "Referenzbild ändern" Link nicht sichtbar
- Einziges Bild ist automatisch Referenz
- Kein Zurücksetzen-Button nötig

## Migration

### Bestehende Daten
- **Alte Leberflecke**: `referenceImageID` ist `nil`
- **Verhalten**: Automatisch ältestes Bild als Referenz
- **Keine Aktion nötig**: Nahtlose Migration

### SwiftData Schema
```swift
// Neue Property ist optional
var referenceImageID: UUID?

// Kein Migrations-Code nötig
// SwiftData handhabt automatisch
```

## Zukünftige Erweiterungen

### Phase 2: Erweiterte Features
- [ ] **Mehrere Referenzbilder**: Verschiedene Referenzen für verschiedene Zwecke
- [ ] **Referenz-Tags**: "Baseline", "Beste Qualität", "Vor Behandlung"
- [ ] **Automatische Auswahl**: KI wählt beste Referenz basierend auf Qualität
- [ ] **Referenz-Historie**: Verlauf der Referenzbild-Änderungen

### Phase 3: Intelligente Assistenz
- [ ] **Qualitäts-Score**: Bewertung jedes Bildes als Referenz
- [ ] **Empfehlungen**: "Dieses Bild eignet sich besser als Referenz"
- [ ] **Vergleichbarkeits-Analyse**: Wie gut passt neue Aufnahme zur Referenz
- [ ] **Automatische Anpassung**: Referenz wechselt bei signifikanten Änderungen

## Best Practices

### Empfehlungen für Benutzer

**Wann erste Aufnahme als Referenz nutzen:**
✅ Langfristige Verlaufskontrolle (Jahre)
✅ Dokumentation von Ausgangszustand
✅ Standardfall für die meisten Leberflecke

**Wann Referenz ändern:**
✅ Leberfleck hat sich deutlich verändert
✅ Bessere Aufnahme verfügbar (Qualität)
✅ Spezifischer Vergleichszeitpunkt gewünscht
✅ Nach medizinischer Behandlung (neue Baseline)

**Wann zurücksetzen:**
✅ Zurück zur langfristigen Vergleichbarkeit
✅ Nach Experiment mit verschiedenen Referenzen
✅ Bei Unsicherheit → Standard ist sicher

## Datum
Implementiert: 11. Januar 2026

## Dateien
- `MoleTracker/Models/Mole.swift` - Datenmodell mit Referenzbild-Logik
- `MoleTracker/Views/MoleDetailView.swift` - UI für Auswahl und Anzeige
- `MoleTracker/Views/CameraView.swift` - Overlay-Integration