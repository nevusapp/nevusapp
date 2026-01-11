# Einzelbild-Export Funktion

## Übersicht
Die App unterstützt jetzt den Export einzelner Bilder als JPEG-Dateien, die direkt in Messaging-Apps und anderen Anwendungen geteilt werden können.

## Funktionalität

### Export-Funktion
- **Dateiformat**: JPEG mit 95% Qualität
- **Dateiname**: `Mole_YYYY-MM-DD_HH-mm-ss.jpg` (basierend auf Aufnahmedatum)
- **Speicherort**: Documents-Verzeichnis (für iOS Share Sheet Zugriff)

### Benutzeroberfläche
- **Share-Button**: In der Toolbar der Bilddetailansicht (oben rechts)
- **Icon**: Standard iOS "square.and.arrow.up" Symbol
- **Feedback**: ProgressView während des Exports
- **Share Sheet**: Native iOS Teilen-Oberfläche mit allen verfügbaren Optionen

## Implementierung

### ExportService.swift
Neue Methode hinzugefügt:
```swift
static func exportImage(_ image: MoleImage) -> URL?
```

**Funktionsweise:**
1. Extrahiert UIImage aus MoleImage
2. Erstellt Dateinamen mit Zeitstempel
3. Konvertiert zu JPEG mit 95% Qualität
4. Speichert in Documents-Verzeichnis
5. Gibt URL zurück für Share Sheet

### ImageDetailView
**Neue State-Variablen:**
- `@State private var exportURL: URL?` - URL des exportierten Bildes
- `@State private var isExporting = false` - Export-Status

**UI-Komponenten:**
- Toolbar-Button mit Share-Icon
- ProgressView während Export
- Share Sheet für Teilen-Optionen

**Export-Funktion:**
```swift
private func exportImage() {
    isExporting = true
    
    Task.detached(priority: .userInitiated) {
        if let url = ExportService.exportImage(image) {
            await MainActor.run {
                exportURL = url
                isExporting = false
            }
        } else {
            await MainActor.run {
                isExporting = false
            }
        }
    }
}
```

## Verwendung

### Für Benutzer
1. Öffnen Sie einen Leberfleck in der Detailansicht
2. Tippen Sie auf ein Bild, um es in voller Größe anzuzeigen
3. Tippen Sie auf das Share-Icon (oben rechts)
4. Warten Sie kurz, während das Bild exportiert wird
5. Wählen Sie eine Teilen-Option aus dem Share Sheet:
   - **Messaging Apps**: WhatsApp, iMessage, Telegram, etc.
   - **E-Mail**: Mail-App
   - **Cloud-Dienste**: iCloud Drive, Dropbox, Google Drive, etc.
   - **Soziale Medien**: (falls gewünscht)
   - **Andere Apps**: Alle Apps, die Bilder akzeptieren
   - **Speichern**: In Fotos-App speichern

### Vorteile
- **Direktes Teilen**: Keine zusätzlichen Schritte erforderlich
- **Hohe Qualität**: 95% JPEG-Qualität für medizinische Dokumentation
- **Zeitstempel**: Dateiname enthält Aufnahmedatum
- **Native Integration**: Nutzt iOS Share Sheet für beste Kompatibilität
- **Sofortige Vorschau**: In Messaging-Apps direkt sichtbar

## Technische Details

### Dateiformat
- **Format**: JPEG
- **Kompression**: 0.95 (95% Qualität)
- **Farbprofil**: Standard RGB
- **Metadaten**: Keine EXIF-Daten (Datenschutz)

### Speicherverwaltung
- Temporäre Dateien werden im Documents-Verzeichnis erstellt
- iOS verwaltet automatisch die Bereinigung nach dem Teilen
- Keine manuelle Bereinigung erforderlich

### Performance
- Export läuft asynchron (Task.detached)
- UI bleibt während Export responsiv
- ProgressView zeigt Aktivität an
- Priorität: .userInitiated für schnelle Verarbeitung

## Unterschied zu anderen Export-Optionen

### Einzelbild-Export (NEU)
- **Format**: JPEG
- **Verwendung**: Direktes Teilen in Apps
- **Metadaten**: Keine
- **Zugriff**: Über Bilddetailansicht

### Leberfleck-Export (Bestehend)
- **Format**: ZIP mit Bildern + JSON-Metadaten
- **Verwendung**: Vollständige Dokumentation
- **Metadaten**: Umfassend (Sensordaten, Datum, etc.)
- **Zugriff**: Über Leberfleck-Detailansicht

### Alle-Leberflecke-Export (Bestehend)
- **Format**: ZIP mit allen Daten
- **Verwendung**: Backup/Archivierung
- **Metadaten**: Vollständig
- **Zugriff**: Über Hauptansicht

## Anwendungsfälle

1. **Arztbesuch**: Schnelles Teilen eines Bildes per E-Mail oder Messenger
2. **Zweite Meinung**: Bild an anderen Arzt senden
3. **Dokumentation**: Bild in externe Dokumentations-App übertragen
4. **Backup**: Einzelnes Bild in Cloud-Dienst speichern
5. **Vergleich**: Bild in andere Analyse-App exportieren

## Datenschutz
- Keine EXIF-Metadaten im exportierten Bild
- Keine GPS-Koordinaten
- Keine Geräteinformationen
- Nur das Bild selbst wird exportiert
- Dateiname enthält nur Datum/Zeit, keine persönlichen Daten

## Datum
Implementiert: 10. Januar 2026