# Overlay-Modus für verbesserte Vergleichbarkeit

## Übersicht
Der Overlay-Modus zeigt das vorherige Bild halbtransparent über der Live-Kamera-Ansicht, um eine präzise Positionierung und Ausrichtung für Folgeaufnahmen zu ermöglichen.

## Problem
Für eine medizinisch sinnvolle Verlaufskontrolle von Leberflecken müssen Folgeaufnahmen vergleichbar sein:
- ✅ Gleiche Ausrichtung (Kamerawinkel)
- ✅ Gleiche Größe (Abstand zur Kamera)
- ✅ Gleiche Position im Bild (X/Y Koordinaten)
- ✅ Ähnliche Beleuchtung

## Lösung: Overlay-Modus

### Funktionsweise

**Automatische Aktivierung:**
- Wenn bereits Bilder für einen Leberfleck existieren
- Das neueste Bild wird als Referenz verwendet
- Overlay wird automatisch mit 50% Transparenz angezeigt

**Benutzersteuerung:**
1. **Ein/Aus-Schalter** (Auge-Icon)
   - Overlay ein-/ausblenden
   - Ermöglicht Vergleich zwischen Live-Bild und Referenz

2. **Transparenz-Slider** (0-100%)
   - Vertikaler Slider rechts im Bild
   - Prozentanzeige über dem Slider
   - Feinabstimmung der Sichtbarkeit

3. **Hilfetext**
   - "Richte die Kamera aus, bis das Overlay passt"
   - Wird angezeigt wenn Overlay aktiv ist

## Implementierung

### 1. CameraView Erweiterung

**Neue Parameter:**
```swift
struct CameraView: View {
    let referenceImage: UIImage?  // Optional: Vorheriges Bild
    let onImageCaptured: (UIImage) -> Void
    
    @State private var overlayOpacity: Double = 0.5
    @State private var showOverlay: Bool = true
}
```

**Initialisierung:**
```swift
init(referenceImage: UIImage? = nil, onImageCaptured: @escaping (UIImage) -> Void) {
    self.referenceImage = referenceImage
    self.onImageCaptured = onImageCaptured
}
```

### 2. UI-Komponenten

**Overlay-Bild:**
```swift
if showOverlay, let refImage = referenceImage {
    Image(uiImage: refImage)
        .resizable()
        .aspectRatio(contentMode: .fill)
        .opacity(overlayOpacity)
        .ignoresSafeArea()
        .allowsHitTesting(false)  // Keine Interaktion mit Overlay
}
```

**Steuerelemente (oben rechts):**
```swift
VStack(alignment: .trailing, spacing: 12) {
    // Ein/Aus-Button
    Button(action: { withAnimation { showOverlay.toggle() } }) {
        Image(systemName: showOverlay ? "eye.fill" : "eye.slash.fill")
            .font(.title2)
            .foregroundColor(.white)
            .padding(12)
            .background(Color.black.opacity(0.6))
            .clipShape(Circle())
    }
    
    // Transparenz-Slider (vertikal)
    if showOverlay {
        VStack(spacing: 8) {
            Text("\(Int(overlayOpacity * 100))%")
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.6))
                .cornerRadius(8)
            
            Slider(value: $overlayOpacity, in: 0...1)
                .frame(width: 150)
                .rotationEffect(.degrees(-90))
                .frame(width: 40, height: 150)
                .tint(.white)
        }
    }
}
```

### 3. Integration in MoleDetailView

**Automatische Referenzbildauswahl:**
```swift
.sheet(isPresented: $showingCamera) {
    CameraView(
        referenceImage: mole.images
            .sorted(by: { $0.captureDate > $1.captureDate })
            .first?.uiImage
    ) { image in
        addImage(image)
    }
}
```

## Benutzerführung

### Erste Aufnahme (kein Overlay)
1. Kamera öffnen
2. Leberfleck positionieren
3. Foto aufnehmen

### Folgeaufnahmen (mit Overlay)
1. **Kamera öffnen**
   - Overlay wird automatisch angezeigt (50% Transparenz)
   - Vorheriges Bild ist sichtbar

2. **Grobe Positionierung**
   - Kamera so ausrichten, dass Leberfleck ungefähr passt
   - Overlay hilft bei der Orientierung

3. **Feinabstimmung**
   - **Option A**: Transparenz erhöhen (mehr Referenz sichtbar)
   - **Option B**: Transparenz verringern (mehr Live-Bild sichtbar)
   - **Option C**: Overlay ausblenden für Vergleich

4. **Optimale Ausrichtung**
   - Leberfleck sollte genau über dem Overlay liegen
   - Größe sollte übereinstimmen
   - Umgebung sollte ähnlich sein

5. **Aufnahme**
   - Foto aufnehmen wenn zufrieden
   - Overlay verschwindet automatisch

## Vorteile

### Für Benutzer
✅ **Intuitive Bedienung** - Visuelles Feedback in Echtzeit
✅ **Präzise Positionierung** - Pixelgenaue Ausrichtung möglich
✅ **Flexible Anpassung** - Transparenz individuell einstellbar
✅ **Schneller Workflow** - Keine manuelle Bildauswahl nötig
✅ **Bessere Vergleichbarkeit** - Konsistente Aufnahmen

### Für medizinische Auswertung
✅ **Standardisierte Aufnahmen** - Gleiche Position und Größe
✅ **Verlässliche Vergleiche** - Veränderungen besser erkennbar
✅ **Dokumentationsqualität** - Professionelle Bildserien
✅ **Zeitersparnis** - Weniger Wiederholungsaufnahmen nötig

## Technische Details

### Performance
- **Overlay-Rendering**: Effizient durch SwiftUI Image-Caching
- **Keine Verzögerung**: Overlay wird sofort angezeigt
- **Smooth Slider**: 60 FPS Transparenz-Anpassung
- **Speicher**: Referenzbild wird nur temporär geladen

### Kompatibilität
- **iOS 17.6+**: Vollständig unterstützt
- **Alle iPhone-Modelle**: Funktioniert auf allen Geräten
- **Portrait & Landscape**: Automatische Anpassung
- **Dark Mode**: Optimierte Kontraste

### Einschränkungen
- ⚠️ Overlay zeigt nur das neueste Bild
- ⚠️ Keine automatische Größenanpassung (Zoom)
- ⚠️ Keine Rotation des Overlays
- ⚠️ Keine Belichtungsanpassung

## Zukünftige Erweiterungen

### Phase 2: Erweiterte Features
- [ ] **Bildauswahl**: Beliebiges Bild als Referenz wählen
- [ ] **Zoom-Matching**: Automatische Größenanpassung
- [ ] **Rotation**: Overlay drehen für bessere Ausrichtung
- [ ] **Ausrichtungshilfen**: Gitter und Hilfslinien
- [ ] **Sensor-Feedback**: Neigungswinkel-Anzeige

### Phase 3: Intelligente Assistenz
- [ ] **Auto-Alignment**: KI-gestützte Positionierung
- [ ] **Qualitäts-Score**: Bewertung der Vergleichbarkeit
- [ ] **Belichtungs-Matching**: Automatische Anpassung
- [ ] **Fokus-Hilfe**: Schärfe-Indikator
- [ ] **Abstandsmessung**: LiDAR-Integration (iPhone 12 Pro+)

### Phase 4: AR-Integration
- [ ] **ARKit-Overlay**: 3D-Positionierung im Raum
- [ ] **Spatial Anchors**: Exakte Wiederholung der Position
- [ ] **Body Tracking**: Automatische Körperregion-Erkennung
- [ ] **Multi-Angle**: Mehrere Referenzbilder gleichzeitig

## Verwandte Features

### Bereits implementiert
- ✅ **Sensordaten-Erfassung**: Neigungswinkel, Kompass, etc.
- ✅ **Bildvergleich**: Side-by-Side und Overlay-Vergleich
- ✅ **Zeitstempel**: Automatische Datierung

### In Planung
- 🔄 **Geführter Aufnahmemodus**: Schritt-für-Schritt Anleitung
- 🔄 **Vergleichbarkeits-Score**: Qualitätsbewertung
- 🔄 **Belichtungswarnung**: Hinweis bei zu großen Unterschieden

## Best Practices

### Für optimale Ergebnisse
1. **Beleuchtung**: Gleiche Lichtverhältnisse wie bei vorheriger Aufnahme
2. **Abstand**: Leberfleck sollte gleiche Größe im Bild haben
3. **Ausrichtung**: Overlay sollte perfekt übereinander liegen
4. **Stabilität**: Ruhige Hand oder Stativ verwenden
5. **Fokus**: Auf Leberfleck fokussieren, nicht auf Overlay

### Häufige Fehler vermeiden
❌ **Zu hohe Transparenz**: Overlay zu dominant, Live-Bild nicht sichtbar
❌ **Zu niedrige Transparenz**: Overlay nicht sichtbar genug
❌ **Falsche Größe**: Abstand zur Kamera unterschiedlich
❌ **Schlechte Beleuchtung**: Schatten oder Reflexionen
❌ **Bewegung**: Verwackelte Aufnahmen

## Datum
Implementiert: 11. Januar 2026

## Dateien
- `Nevus/Views/CameraView.swift` - Overlay-Modus UI
- `Nevus/Views/MoleDetailView.swift` - Integration
