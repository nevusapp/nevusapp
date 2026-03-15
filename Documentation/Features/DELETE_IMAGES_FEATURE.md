# Bilder Löschen Feature

## Übersicht
Benutzer können jetzt sowohl Leberfleck-Detailbilder als auch Übersichtsbilder mit einem Bestätigungsdialog löschen.

## Implementierung

### 1. Leberfleck-Detailbilder (MoleImage)

**Datei:** `Nevus/Views/MoleDetailView.swift` - `ImageDetailView`

**UI-Änderungen:**
- Toolbar-Button wurde von einzelnem Share-Button zu **Menü** geändert
- Menü enthält:
  - "Teilen" (mit Share-Icon)
  - "Löschen" (mit Trash-Icon, destructive role)

**Bestätigungsdialog:**
```swift
.alert("Bild löschen?", isPresented: $showingDeleteConfirmation) {
    Button("Abbrechen", role: .cancel) { }
    Button("Löschen", role: .destructive) {
        deleteImage()
    }
} message: {
    Text("Möchten Sie dieses Bild wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.")
}
```

**Lösch-Funktion:**
```swift
private func deleteImage() {
    if let mole = image.mole {
        mole.updateModifiedDate()  // Update parent mole timestamp
    }
    modelContext.delete(image)
    dismiss()  // Close detail view
}
```

### 2. Übersichtsbilder (BodyRegionOverview)

**Datei:** `Nevus/Views/RegionOverviewView.swift` - `OverviewImageDetailView`

**UI-Änderungen:**
- "Bearbeiten"/"Fertig" Button wurde in **Menü** integriert
- Menü enthält:
  - "Bearbeiten"/"Fertig" (für Notizen)
  - "Löschen" (mit Trash-Icon, destructive role)

**Bestätigungsdialog:**
```swift
.alert("Übersichtsbild löschen?", isPresented: $showingDeleteConfirmation) {
    Button("Abbrechen", role: .cancel) { }
    Button("Löschen", role: .destructive) {
        deleteOverview()
    }
} message: {
    Text("Möchten Sie dieses Übersichtsbild wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.")
}
```

**Lösch-Funktion:**
```swift
private func deleteOverview() {
    modelContext.delete(overview)
    dismiss()  // Close detail view
}
```

## Benutzerführung

### Leberfleck-Detailbild löschen:

1. **Bild öffnen**
   - Leberfleck-Detailansicht → Bild antippen

2. **Menü öffnen**
   - Drei-Punkte-Icon (⋯) oben rechts antippen

3. **Löschen wählen**
   - "Löschen" Option antippen (rot markiert)

4. **Bestätigen**
   - Bestätigungsdialog erscheint
   - "Löschen" antippen zum Bestätigen
   - "Abbrechen" zum Abbrechen

5. **Ergebnis**
   - Bild wird gelöscht
   - Detailansicht schließt sich automatisch
   - Leberfleck-Änderungsdatum wird aktualisiert

### Übersichtsbild löschen:

**Option 1: Aus Detailansicht**

1. **Bild öffnen**
   - Übersichtsbild antippen

2. **Menü öffnen**
   - Drei-Punkte-Icon (⋯) oben rechts antippen

3. **Löschen wählen**
   - "Löschen" Option antippen (rot markiert)

4. **Bestätigen**
   - Bestätigungsdialog erscheint
   - "Löschen" antippen zum Bestätigen

5. **Ergebnis**
   - Bild wird gelöscht
   - Detailansicht schließt sich automatisch

**Option 2: Aus Grid-Ansicht (bereits vorhanden)**

1. **Long-Press** auf Thumbnail
2. **Context-Menü** erscheint
3. **"Löschen"** wählen
4. Sofortiges Löschen ohne zusätzlichen Dialog

## UI-Komponenten

### Menü-Button
```swift
Menu {
    // Aktionen
} label: {
    Image(systemName: "ellipsis.circle")
}
```

### Alert-Dialog
- **Titel**: "Bild löschen?" / "Übersichtsbild löschen?"
- **Nachricht**: Warnung über Unwiderruflichkeit
- **Buttons**:
  - "Abbrechen" (cancel role)
  - "Löschen" (destructive role, rot)

## Technische Details

### State-Variablen
```swift
@State private var showingDeleteConfirmation = false
```

### Environment-Variablen
```swift
@Environment(\.modelContext) private var modelContext
@Environment(\.dismiss) private var dismiss
```

### SwiftData Cascade Delete
- Leberfleck-Bilder: Automatisch gelöscht wenn Leberfleck gelöscht wird
- Übersichtsbilder: Unabhängig, müssen einzeln gelöscht werden

## Sicherheitsmerkmale

### Bestätigungsdialog
✅ **Verhindert versehentliches Löschen**
- Klare Warnung über Unwiderruflichkeit
- Zwei-Schritt-Prozess (Menü → Bestätigung)
- Destructive role (rote Farbe) für Löschen-Button

### Automatisches Schließen
✅ **Verhindert Fehler**
- View schließt sich nach Löschen automatisch
- Keine "leere" Detailansicht
- Zurück zur vorherigen Ansicht

### Timestamp-Update
✅ **Konsistenz**
- Leberfleck-Änderungsdatum wird aktualisiert
- Sortierung bleibt korrekt
- Änderungen sind nachvollziehbar

## Unterschiede zwischen Lösch-Methoden

### Context-Menü (Grid-Ansicht)
- **Zugriff**: Long-Press auf Thumbnail
- **Bestätigung**: Keine
- **Verwendung**: Schnelles Löschen mehrerer Bilder
- **Verfügbar für**: Nur Übersichtsbilder

### Menü + Alert (Detailansicht)
- **Zugriff**: Drei-Punkte-Menü
- **Bestätigung**: Ja (Alert-Dialog)
- **Verwendung**: Sicheres Löschen einzelner Bilder
- **Verfügbar für**: Beide Bildtypen

## Vorteile

### Für Benutzer
✅ **Sicherheit** - Bestätigungsdialog verhindert Fehler
✅ **Flexibilität** - Zwei Lösch-Methoden je nach Kontext
✅ **Klarheit** - Deutliche Warnung über Konsequenzen
✅ **Konsistenz** - Gleiche UI-Patterns in beiden Views

### Für Entwickler
✅ **SwiftData Integration** - Automatische Cascade Deletes
✅ **Clean Code** - Separate Lösch-Funktionen
✅ **Error Handling** - Dismiss nach Löschen
✅ **Maintainability** - Konsistente Implementierung

## Zukünftige Erweiterungen

### Mögliche Features
- [ ] Undo-Funktion (Rückgängig machen)
- [ ] Papierkorb mit zeitlich begrenzter Wiederherstellung
- [ ] Batch-Delete (mehrere Bilder gleichzeitig)
- [ ] Export vor Löschen (automatisches Backup)
- [ ] Lösch-Statistiken (gelöschte Bilder zählen)

## Datum
Implementiert: 11. Januar 2026
