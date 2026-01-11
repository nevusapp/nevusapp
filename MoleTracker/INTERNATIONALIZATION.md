# Internationalisierung / Internationalization

## Übersicht / Overview

Die MoleTracker App wurde vollständig internationalisiert und unterstützt mehrere Sprachen.

The MoleTracker app has been fully internationalized and supports multiple languages.

## Unterstützte Sprachen / Supported Languages

- 🇩🇪 Deutsch (German) - Base Language
- 🇬🇧 English

## Implementierung / Implementation

### String Catalog

Die App verwendet das moderne **String Catalog** System von Xcode 15+:
- Datei: `MoleTracker/Localizable.xcstrings`
- Format: JSON-basiert
- Automatische Pluralisierung und Variablen-Unterstützung

The app uses the modern **String Catalog** system from Xcode 15+:
- File: `MoleTracker/Localizable.xcstrings`
- Format: JSON-based
- Automatic pluralization and variable support

### Lokalisierte Komponenten / Localized Components

#### 1. UI-Texte / UI Texts
Alle Benutzeroberflächen-Texte verwenden `String(localized:)`:
```swift
Text(String(localized: "title_mole_list"))
Button(String(localized: "action_save"))
```

#### 2. Enumerationen / Enumerations

**BodyRegion** und **BodySide** Enums haben lokalisierte Namen:
```swift
enum BodyRegion {
    var localizedName: String {
        switch self {
        case .head: return String(localized: "body_region_head")
        // ...
        }
    }
}
```

#### 3. Rückwärtskompatibilität / Backward Compatibility

Die Enums behalten ihre ursprünglichen deutschen Werte für bestehende Daten:
```swift
var legacyRawValue: String {
    switch self {
    case .head: return "Kopf"
    // ...
    }
}
```

### Lokalisierte Dateien / Localized Files

- ✅ `ContentView.swift` - Hauptansicht / Main view
- ✅ `MoleDetailView.swift` - Detailansicht / Detail view
- ✅ `Models/Mole.swift` - Datenmodell / Data model
- ✅ `Localizable.xcstrings` - String-Katalog / String catalog

## Neue Sprache hinzufügen / Adding a New Language

### In Xcode:

1. Öffne das Projekt in Xcode / Open project in Xcode
2. Wähle das Projekt im Navigator / Select project in navigator
3. Gehe zu **Info** Tab
4. Unter **Localizations** klicke auf **+**
5. Wähle die gewünschte Sprache / Select desired language
6. Öffne `Localizable.xcstrings`
7. Füge Übersetzungen hinzu / Add translations

### Programmatisch / Programmatically:

Bearbeite `Localizable.xcstrings` und füge neue Spracheinträge hinzu:
```json
{
  "strings": {
    "title_mole_list": {
      "localizations": {
        "de": { "stringUnit": { "value": "Meine Leberflecke" } },
        "en": { "stringUnit": { "value": "My Moles" } },
        "fr": { "stringUnit": { "value": "Mes Grains de Beauté" } }
      }
    }
  }
}
```

## String-Kategorien / String Categories

### Navigation & Titel / Navigation & Titles
- `title_mole_list` - Haupttitel
- `title_mole_detail` - Detailansicht
- `title_add_mole` - Neuer Leberfleck

### Körperregionen / Body Regions
- `body_region_head` - Kopf / Head
- `body_region_neck` - Hals / Neck
- `body_region_arm_left` - Arm links / Left arm
- etc.

### Körperseiten / Body Sides
- `body_side_head_front` - Vorne/Gesicht / Front/Face
- `body_side_torso_left` - Links / Left
- etc.

### Aktionen / Actions
- `action_add` - Hinzufügen / Add
- `action_save` - Speichern / Save
- `action_delete` - Löschen / Delete
- `action_export` - Exportieren / Export

### Meldungen / Messages
- `empty_moles_title` - Keine Leberflecke erfasst
- `delete_confirmation_mole` - Löschbestätigung
- `exporting_data` - Exportiere Daten...

## Testen / Testing

### Im Simulator / In Simulator:
1. Öffne Einstellungen / Open Settings
2. Gehe zu **Allgemein > Sprache & Region** / Go to **General > Language & Region**
3. Ändere die Sprache / Change language
4. Starte die App neu / Restart app

### In Xcode:
1. Wähle Schema / Select scheme
2. **Edit Scheme** > **Run** > **Options**
3. Setze **App Language** auf gewünschte Sprache / Set to desired language

## Best Practices

1. **Immer String(localized:) verwenden** / Always use String(localized:)
   ```swift
   // ✅ Gut / Good
   Text(String(localized: "action_save"))
   
   // ❌ Schlecht / Bad
   Text("Speichern")
   ```

2. **Kontext für Übersetzer bereitstellen** / Provide context for translators
   ```swift
   String(localized: "section_images_count", 
          defaultValue: "Images (\(count))", 
          comment: "Section header with image count")
   ```

3. **Datum/Zeit automatisch formatieren** / Auto-format dates/times
   ```swift
   // Automatisch lokalisiert / Automatically localized
   date.formatted(date: .long, time: .shortened)
   ```

4. **Pluralisierung nutzen** / Use pluralization
   ```swift
   String(localized: "^[\(count) image](inflect: true)")
   ```

## Wartung / Maintenance

- Neue Strings immer zu `Localizable.xcstrings` hinzufügen
- Alle Sprachen gleichzeitig aktualisieren
- Regelmäßig auf fehlende Übersetzungen prüfen

- Always add new strings to `Localizable.xcstrings`
- Update all languages simultaneously
- Regularly check for missing translations

## Ressourcen / Resources

- [Apple Localization Guide](https://developer.apple.com/localization/)
- [String Catalogs Documentation](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog)