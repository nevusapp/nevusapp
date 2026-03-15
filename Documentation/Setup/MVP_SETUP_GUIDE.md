# Nevus MVP - Setup-Anleitung für iPhone-Testing

Diese Anleitung führt Sie durch alle Schritte, um ein funktionsfähiges MVP (Minimum Viable Product) der Nevus-App auf Ihrem iPhone zu testen.

## 📋 Voraussetzungen

### Hardware
- ✅ Mac mit macOS Ventura (13.0) oder neuer
- ✅ iPhone mit iOS 16.0 oder neuer
- ✅ USB-C oder Lightning-Kabel für iPhone-Verbindung

### Software
- ✅ Xcode 15.0 oder neuer (kostenlos im Mac App Store)
- ✅ Apple Developer Account (kostenlos für Testing auf eigenem Gerät)

### Kenntnisse
- Grundlegende Swift/SwiftUI-Kenntnisse (empfohlen)
- Alternativ: Bereitschaft, Tutorials zu folgen

## 🎯 MVP-Funktionsumfang

Für das erste testbare MVP konzentrieren wir uns auf die Kernfunktionen:

### ✅ Enthalten im MVP
1. **Bildaufnahme**: Kamera-Integration für Leberfleck-Fotos
2. **Speicherung**: Lokale Speicherung mit SwiftData
3. **Liste**: Übersicht aller erfassten Leberflecke
4. **Detail-Ansicht**: Einzelne Leberflecke mit Bildern anzeigen
5. **Einfacher Vergleich**: Zwei Bilder nebeneinander anzeigen
6. **Notizen**: Textnotizen zu jedem Leberfleck

### ⏭️ Für spätere Versionen
- Sensor-basierte automatische Zuordnung
- ML-Feature-Extraktion
- Körperkarte
- iCloud-Sync
- Erweiterte Vergleichstools

## 🚀 Schritt-für-Schritt-Anleitung

### Schritt 1: Xcode installieren

1. Öffnen Sie den **Mac App Store**
2. Suchen Sie nach **"Xcode"**
3. Klicken Sie auf **"Laden"** (ca. 7 GB Download)
4. Warten Sie, bis die Installation abgeschlossen ist
5. Öffnen Sie Xcode und akzeptieren Sie die Lizenzbedingungen

### Schritt 2: Apple Developer Account einrichten

1. Öffnen Sie **Xcode**
2. Gehen Sie zu **Xcode → Settings** (oder Preferences)
3. Wählen Sie den Tab **"Accounts"**
4. Klicken Sie auf **"+"** und wählen Sie **"Apple ID"**
5. Melden Sie sich mit Ihrer Apple ID an
6. Warten Sie, bis Ihr Account verifiziert ist

**Hinweis**: Für Testing auf Ihrem eigenen iPhone ist keine kostenpflichtige Developer-Mitgliedschaft erforderlich!

### Schritt 3: Neues Xcode-Projekt erstellen

1. Öffnen Sie **Xcode**
2. Wählen Sie **"Create New Project"**
3. Wählen Sie **iOS → App**
4. Klicken Sie auf **"Next"**

**Projekt-Einstellungen:**
- **Product Name**: `Nevus`
- **Team**: Wählen Sie Ihren Apple ID Account
- **Organization Identifier**: `com.yourname` (z.B. `com.wolfram`)
- **Bundle Identifier**: Wird automatisch generiert (z.B. `com.wolfram.Nevus`)
- **Interface**: **SwiftUI**
- **Storage**: **SwiftData**
- **Language**: **Swift**

5. Klicken Sie auf **"Next"**
6. Wählen Sie einen Speicherort (z.B. Desktop/Nevus)
7. Klicken Sie auf **"Create"**

### Schritt 4: Projekt-Struktur erstellen

Erstellen Sie folgende Ordner-Struktur in Xcode:

1. Rechtsklick auf **Nevus** (gelber Ordner) → **New Group**
2. Erstellen Sie diese Gruppen:
   - `Models`
   - `Views`
   - `ViewModels`
   - `Services`

### Schritt 5: Datenmodelle implementieren

#### 5.1 Mole Model erstellen

1. Rechtsklick auf **Models** → **New File**
2. Wählen Sie **Swift File**
3. Name: `Mole.swift`

```swift
import Foundation
import SwiftData

@Model
final class Mole {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var lastModified: Date
    var bodyRegion: String
    var notes: String
    
    @Relationship(deleteRule: .cascade)
    var images: [MoleImage]
    
    init(bodyRegion: String) {
        self.id = UUID()
        self.createdAt = Date()
        self.lastModified = Date()
        self.bodyRegion = bodyRegion
        self.notes = ""
        self.images = []
    }
}
```

#### 5.2 MoleImage Model erstellen

1. Rechtsklick auf **Models** → **New File**
2. Name: `MoleImage.swift`

```swift
import Foundation
import SwiftData

@Model
final class MoleImage {
    @Attribute(.unique) var id: UUID
    var captureDate: Date
    @Attribute(.externalStorage) var imageData: Data
    var thumbnailData: Data
    
    var mole: Mole?
    
    init(imageData: Data, thumbnailData: Data) {
        self.id = UUID()
        self.captureDate = Date()
        self.imageData = imageData
        self.thumbnailData = thumbnailData
    }
}
```

### Schritt 6: App-Entry-Point konfigurieren

Öffnen Sie `NevusApp.swift` und ersetzen Sie den Inhalt:

```swift
import SwiftUI
import SwiftData

@main
struct NevusApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Mole.self, MoleImage.self])
    }
}
```

### Schritt 7: Basis-UI implementieren

#### 7.1 ContentView (Hauptansicht)

Ersetzen Sie `ContentView.swift`:

```swift
import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var moles: [Mole]
    @State private var showingCamera = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(moles) { mole in
                    NavigationLink(destination: MoleDetailView(mole: mole)) {
                        MoleRowView(mole: mole)
                    }
                }
                .onDelete(perform: deleteMoles)
            }
            .navigationTitle("Meine Leberflecke")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: addMole) {
                        Label("Hinzufügen", systemImage: "plus")
                    }
                }
            }
        }
    }
    
    private func addMole() {
        let newMole = Mole(bodyRegion: "Unbekannt")
        modelContext.insert(newMole)
    }
    
    private func deleteMoles(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(moles[index])
        }
    }
}

struct MoleRowView: View {
    let mole: Mole
    
    var body: some View {
        HStack {
            if let firstImage = mole.images.first,
               let uiImage = UIImage(data: firstImage.thumbnailData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    }
            }
            
            VStack(alignment: .leading) {
                Text(mole.bodyRegion)
                    .font(.headline)
                Text("\(mole.images.count) Bilder")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
```

#### 7.2 MoleDetailView erstellen

1. Rechtsklick auf **Views** → **New File** → **SwiftUI View**
2. Name: `MoleDetailView.swift`

```swift
import SwiftUI
import SwiftData

struct MoleDetailView: View {
    @Bindable var mole: Mole
    @State private var showingCamera = false
    
    var body: some View {
        List {
            Section("Bilder") {
                ForEach(mole.images) { image in
                    if let uiImage = UIImage(data: image.imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                    }
                }
            }
            
            Section("Notizen") {
                TextEditor(text: $mole.notes)
                    .frame(minHeight: 100)
            }
            
            Section("Details") {
                LabeledContent("Erstellt", value: mole.createdAt.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Anzahl Bilder", value: "\(mole.images.count)")
            }
        }
        .navigationTitle(mole.bodyRegion)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Foto") {
                    showingCamera = true
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            Text("Kamera-Integration folgt")
        }
    }
}
```

### Schritt 8: Berechtigungen konfigurieren

1. Öffnen Sie **Info.plist** (oder Info-Tab im Project Navigator)
2. Fügen Sie folgende Einträge hinzu:

**Rechtsklick auf Info.plist → Open As → Source Code**, dann einfügen:

```xml
<key>NSCameraUsageDescription</key>
<string>Nevus benötigt Zugriff auf die Kamera, um Fotos von Leberflecken aufzunehmen.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Nevus benötigt Zugriff auf die Fotobibliothek, um Bilder zu speichern.</string>
```

### Schritt 9: iPhone vorbereiten

1. Verbinden Sie Ihr iPhone mit dem Mac (USB-Kabel)
2. Entsperren Sie das iPhone
3. Wenn gefragt, tippen Sie auf **"Vertrauen"** auf dem iPhone
4. Geben Sie Ihren iPhone-Code ein

### Schritt 10: App auf iPhone installieren

1. In Xcode, oben links: Wählen Sie Ihr iPhone aus dem Dropdown
   (z.B. "Wolframs iPhone" statt "iPhone 15 Pro Simulator")

2. Klicken Sie auf den **Play-Button** (▶️) oder drücken Sie **Cmd + R**

3. Xcode wird die App kompilieren und auf Ihr iPhone übertragen

4. **Wichtig**: Beim ersten Mal erscheint auf dem iPhone eine Fehlermeldung:
   - Gehen Sie auf dem iPhone zu **Einstellungen → Allgemein → VPN & Geräteverwaltung**
   - Tippen Sie auf Ihre Apple ID
   - Tippen Sie auf **"Vertrauen"**
   - Bestätigen Sie

5. Starten Sie die App erneut in Xcode (▶️)

### Schritt 11: App testen

Die App sollte jetzt auf Ihrem iPhone laufen! Sie können:

✅ Neue Leberflecke hinzufügen (+ Button)
✅ Leberflecke in der Liste sehen
✅ Details eines Leberflecks öffnen
✅ Notizen hinzufügen
✅ Leberflecke löschen (Swipe nach links)

## 🔄 Nächste Schritte für vollständiges MVP

Um ein vollständig funktionsfähiges MVP zu erhalten, müssen noch folgende Features implementiert werden:

### Phase 1: Kamera-Integration (1-2 Tage)
- [ ] CameraView mit AVFoundation
- [ ] Foto aufnehmen und speichern
- [ ] Thumbnail-Generierung

### Phase 2: Bildvergleich (1 Tag)
- [ ] ComparisonView für Side-by-Side-Vergleich
- [ ] Bildauswahl nach Datum

### Phase 3: Verbesserungen (1-2 Tage)
- [ ] Körperregion-Auswahl
- [ ] Besseres UI-Design
- [ ] Fehlerbehandlung

**Geschätzte Zeit bis zum vollständigen MVP: 3-5 Tage**

## 🐛 Häufige Probleme und Lösungen

### Problem: "Failed to register bundle identifier"
**Lösung**: Ändern Sie den Bundle Identifier in Xcode:
- Projekt auswählen → Target → Signing & Capabilities
- Bundle Identifier ändern (z.B. `com.yourname.Nevus2`)

### Problem: "Untrusted Developer"
**Lösung**: 
- iPhone: Einstellungen → Allgemein → VPN & Geräteverwaltung
- Ihre Apple ID antippen → Vertrauen

### Problem: "No code signing identities found"
**Lösung**:
- Xcode → Settings → Accounts
- Apple ID hinzufügen oder neu anmelden

### Problem: App stürzt beim Start ab
**Lösung**:
- Xcode → Product → Clean Build Folder (Cmd + Shift + K)
- Neu kompilieren

## 📚 Weiterführende Ressourcen

### Apple Dokumentation
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [AVFoundation Camera Guide](https://developer.apple.com/documentation/avfoundation/capture_setup)

### Video-Tutorials
- [Hacking with Swift - SwiftUI](https://www.hackingwithswift.com/100/swiftui)
- [Paul Hudson - SwiftData Tutorial](https://www.hackingwithswift.com/quick-start/swiftdata)

### Community
- [Swift Forums](https://forums.swift.org)
- [Stack Overflow - SwiftUI Tag](https://stackoverflow.com/questions/tagged/swiftui)

## 💡 Empfehlung

Wenn Sie keine Erfahrung mit iOS-Entwicklung haben, empfehle ich:

1. **Option A**: Folgen Sie dieser Anleitung Schritt für Schritt
2. **Option B**: Beauftragen Sie einen iOS-Entwickler für 1-2 Tage
3. **Option C**: Nutzen Sie den Code-Modus, um die vollständige Implementierung zu erhalten

Möchten Sie, dass ich in den **Code-Modus** wechsle und die vollständige MVP-Implementierung erstelle?