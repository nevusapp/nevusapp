# Performance Debugging Guide

## Problem
Kamera-View bleibt 8 Sekunden schwarz nach Foto-Aufnahme, bevor Detail-View erscheint.

## Debugging-Schritte

### 1. Zeitstempel hinzufügen

Fügen Sie temporär print-Statements hinzu, um zu sehen, wo die Verzögerung auftritt:

#### In CameraService.swift (Zeile 159):
```swift
nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    print("📸 [DEBUG] photoOutput called at \(Date())")
    
    if let error = error {
        print("❌ [DEBUG] Error: \(error)")
        Task { @MainActor in
            self.error = .captureFailed(error.localizedDescription)
        }
        return
    }
    
    Task.detached(priority: .userInitiated) {
        print("🔄 [DEBUG] Starting image processing at \(Date())")
        
        guard let imageData = photo.fileDataRepresentation() else {
            print("❌ [DEBUG] Failed to get image data")
            await MainActor.run {
                self.error = .invalidImage
            }
            return
        }
        print("✅ [DEBUG] Got image data (\(imageData.count) bytes) at \(Date())")
        
        guard let image = UIImage(data: imageData) else {
            print("❌ [DEBUG] Failed to create UIImage")
            await MainActor.run {
                self.error = .invalidImage
            }
            return
        }
        print("✅ [DEBUG] Created UIImage at \(Date())")
        
        await MainActor.run {
            print("✅ [DEBUG] Setting capturedImage on MainActor at \(Date())")
            self.capturedImage = image
        }
    }
}
```

#### In CameraView.swift (Zeile 80):
```swift
.onChange(of: cameraService.capturedImage) { _, newValue in
    print("🔔 [DEBUG] onChange triggered at \(Date())")
    
    if let image = newValue {
        print("📷 [DEBUG] Got image, stopping session at \(Date())")
        cameraService.stopSession()
        
        print("🔄 [DEBUG] Resetting capturedImage at \(Date())")
        cameraService.capturedImage = nil
        
        print("👋 [DEBUG] Calling dismiss() at \(Date())")
        dismiss()
        
        Task.detached(priority: .userInitiated) {
            print("🎯 [DEBUG] Calling onImageCaptured at \(Date())")
            await MainActor.run {
                onImageCaptured(image)
                print("✅ [DEBUG] onImageCaptured completed at \(Date())")
            }
        }
    }
}
```

#### In MoleDetailView.swift (Zeile 193):
```swift
private func addImage(_ uiImage: UIImage) {
    print("➕ [DEBUG] addImage called at \(Date())")
    isProcessingImage = true
    
    Task {
        print("🔄 [DEBUG] Creating MoleImage at \(Date())")
        guard let moleImage = await MoleImage.create(from: uiImage) else {
            print("❌ [DEBUG] Failed to create MoleImage")
            await MainActor.run {
                isProcessingImage = false
            }
            return
        }
        print("✅ [DEBUG] MoleImage created at \(Date())")
        
        await MainActor.run {
            print("💾 [DEBUG] Saving to context at \(Date())")
            moleImage.mole = mole
            mole.images.append(moleImage)
            mole.updateModifiedDate()
            
            modelContext.insert(moleImage)
            
            isProcessingImage = false
            print("✅ [DEBUG] addImage completed at \(Date())")
        }
    }
}
```

### 2. Xcode Console analysieren

Nach dem Hinzufügen der Debug-Statements:

1. Bauen und starten Sie die App
2. Nehmen Sie ein Foto auf
3. Schauen Sie in die Xcode Console
4. Notieren Sie die Zeitstempel

### 3. Erwartete Ausgabe

```
📸 [DEBUG] photoOutput called at 2026-01-10 13:00:00
🔄 [DEBUG] Starting image processing at 2026-01-10 13:00:00
✅ [DEBUG] Got image data (5242880 bytes) at 2026-01-10 13:00:01
✅ [DEBUG] Created UIImage at 2026-01-10 13:00:02
✅ [DEBUG] Setting capturedImage on MainActor at 2026-01-10 13:00:02
🔔 [DEBUG] onChange triggered at 2026-01-10 13:00:02
📷 [DEBUG] Got image, stopping session at 2026-01-10 13:00:02
🔄 [DEBUG] Resetting capturedImage at 2026-01-10 13:00:02
👋 [DEBUG] Calling dismiss() at 2026-01-10 13:00:02
🎯 [DEBUG] Calling onImageCaptured at 2026-01-10 13:00:02
➕ [DEBUG] addImage called at 2026-01-10 13:00:02
🔄 [DEBUG] Creating MoleImage at 2026-01-10 13:00:02
✅ [DEBUG] MoleImage created at 2026-01-10 13:00:03
💾 [DEBUG] Saving to context at 2026-01-10 13:00:03
✅ [DEBUG] addImage completed at 2026-01-10 13:00:03
```

### 4. Probleme identifizieren

Schauen Sie nach großen Zeitlücken zwischen den Statements:

- **Wenn Lücke zwischen "photoOutput called" und "Got image data"**: 
  - Problem: `fileDataRepresentation()` ist langsam
  - Lösung: Kann nicht optimiert werden (iOS API)

- **Wenn Lücke zwischen "Got image data" und "Created UIImage"**:
  - Problem: `UIImage(data:)` ist langsam
  - Lösung: Bereits im Background Thread

- **Wenn Lücke zwischen "Calling dismiss()" und "addImage called"**:
  - Problem: SwiftUI dismiss() ist langsam
  - Lösung: Kann nicht direkt optimiert werden

- **Wenn Lücke zwischen "Creating MoleImage" und "MoleImage created"**:
  - Problem: Thumbnail-Generierung ist langsam
  - Lösung: Bereits optimiert mit `preparingThumbnail`

### 5. Alternative Lösungen

Falls das Problem bei `dismiss()` liegt:

#### Option A: Sofortiges visuelles Feedback
```swift
@State private var showDismissOverlay = false

.overlay {
    if showDismissOverlay {
        Color.black
            .ignoresSafeArea()
            .overlay {
                ProgressView()
                    .tint(.white)
            }
    }
}

.onChange(of: cameraService.capturedImage) { _, newValue in
    if let image = newValue {
        showDismissOverlay = true  // Sofort schwarzen Overlay zeigen
        
        cameraService.stopSession()
        cameraService.capturedImage = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            dismiss()
        }
        
        // ... rest
    }
}
```

#### Option B: Fullscreen Cover statt Sheet
In MoleDetailView.swift ändern:
```swift
.fullScreenCover(isPresented: $showingCamera) {  // statt .sheet
    CameraView { image in
        addImage(image)
    }
}
```

### 6. Weitere Checks

- Prüfen Sie, ob iCloud Sync aktiv ist und Daten hochlädt
- Prüfen Sie, ob SwiftData viele Objekte im Context hat
- Prüfen Sie die Bildgröße (sollte nicht > 10 MB sein)

## Nächste Schritte

1. Fügen Sie die Debug-Statements hinzu
2. Testen Sie die App
3. Teilen Sie die Console-Ausgabe
4. Wir können dann die genaue Ursache identifizieren