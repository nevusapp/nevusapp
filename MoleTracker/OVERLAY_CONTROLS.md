# Overlay-Steuerelemente - Benutzerführung

## Übersicht
Die Overlay-Steuerelemente wurden optimiert für bessere Sichtbarkeit und Bedienbarkeit.

## Aktuelle Implementierung

### 1. **Positionierung**
- **Zentriert oben** im Bildschirm
- **Unterhalb der Navigation Bar** (70px Padding)
- **Gut sichtbar** auf allen Geräten

### 2. **Steuerelemente**

#### A) Ein/Aus-Button
- **Icon**: Auge (✅ `eye.fill` / ❌ `eye.slash.fill`)
- **Funktion**: Overlay ein-/ausblenden
- **Stil**: Kreis mit Schatten für bessere Sichtbarkeit

#### B) Transparenz-Slider
- **Horizontaler Slider** (0-100%)
- **Beschriftung**: "Transparenz:"
- **Wertanzeige**: Aktueller Prozentwert
- **Stil**: Dunkler Hintergrund mit Schatten

### 3. **Layout**
```swift
HStack(spacing: 16) {
    // Ein/Aus-Button
    Button(...) {
        Image(systemName: showOverlay ? "eye.fill" : "eye.slash.fill")
            .font(.title2)
            .foregroundColor(.white)
            .padding(12)
            .background(Color.black.opacity(0.7))
            .clipShape(Circle())
            .shadow(radius: 4)
    }

    // Transparenz-Slider (nur wenn Overlay aktiv)
    if showOverlay {
        HStack(spacing: 8) {
            Text("Transparenz:")
                .font(.subheadline)
                .foregroundColor(.white)

            Slider(value: $overlayOpacity, in: 0...1)
                .tint(.white)

            Text("\(Int(overlayOpacity * 100))%")
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(width: 45)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.7))
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}
.frame(maxWidth: .infinity)
.padding(.horizontal, 20)
```

## Benutzerführung

### 1. **Overlay aktivieren/deaktivieren**
- **Button antippen** (Auge-Icon)
- **Animation**: Sanftes Ein-/Ausblenden
- **Standard**: Aktiviert (50% Transparenz)

### 2. **Transparenz anpassen**
- **Slider bewegen** (0-100%)
- **Echtzeit-Feedback**: Overlay passt sich sofort an
- **Wertanzeige**: Aktueller Prozentwert wird angezeigt

### 3. **Optimale Einstellung finden**
- **50% Standard**: Guter Ausgangspunkt
- **Mehr Transparenz** (→ 70-80%): Mehr Live-Bild sichtbar
- **Weniger Transparenz** (→ 30-40%): Mehr Referenzbild sichtbar

## Visuelle Hierarchie

```
┌───────────────────────────────────┐
│           Kamera-Vorschau          │
├───────────────────────────────────┤
│  [Auge-Icon]  [Transparenz-Slider] │ ← Steuerelemente (zentriert)
│                                   │
│                                   │
│                                   │
│                                   │
│          [Aufnahme-Button]        │
└───────────────────────────────────┘
```

## Tipps für beste Ergebnisse

1. **Gute Beleuchtung**: Gleiche Lichtverhältnisse wie bei Referenzbild
2. **Stabile Hand**: Verwacklungen vermeiden
3. **Optimale Transparenz**:
   - 50-60%: Ausgewogener Vergleich
   - 70-80%: Feinabstimmung der Position
   - 30-40%: Starke Orientierung am Referenzbild

## Häufige Fragen

**Q: Warum sehe ich die Steuerelemente nicht?**
A: Prüfen Sie:
- ✅ Referenzbild ist ausgewählt
- ✅ Kamera hat Zugriff auf Fotos
- ✅ Bildschirm ist nicht zu hell (Helligkeit reduzieren)

**Q: Wie setze ich die Transparenz zurück?**
A: Einfach den Slider auf 50% stellen

**Q: Kann ich die Steuerelemente verschieben?**
A: Nein, sie sind fest positioniert für optimale Bedienung

## Datum
Optimiert: 11. Januar 2026