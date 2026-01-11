//
//  GuidedScanningView.swift
//  MoleTracker
//
//  Created on 11.01.2026.
//

import SwiftUI
import SwiftData

struct GuidedScanningView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var scanningService = GuidedScanningService()
    
    let moles: [Mole]
    
    @State private var showingCamera = false
    @State private var showingCancelConfirmation = false
    @State private var showingCompletionSheet = false
    @State private var isProcessingImage = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress Header
                progressHeader
                
                Divider()
                
                // Current Mole Content
                if let currentMole = scanningService.currentMole {
                    currentMoleView(currentMole)
                } else {
                    completionView
                }
            }
            .navigationTitle("Geführtes Scannen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        showingCancelConfirmation = true
                    }
                }
            }
            .sheet(isPresented: $showingCamera) {
                if let mole = scanningService.currentMole {
                    CameraView(referenceImage: mole.referenceImage?.uiImage) { image in
                        addImageToCurrentMole(image)
                    }
                }
            }
            .alert("Scannen abbrechen?", isPresented: $showingCancelConfirmation) {
                Button("Fortsetzen", role: .cancel) { }
                Button("Abbrechen", role: .destructive) {
                    scanningService.cancelScanning()
                    dismiss()
                }
            } message: {
                Text("Möchten Sie das geführte Scannen wirklich abbrechen? Ihr Fortschritt geht verloren.")
            }
            .sheet(isPresented: $showingCompletionSheet) {
                completionSummarySheet
            }
            .onAppear {
                scanningService.startScanning(moles: moles)
            }
        }
    }
    
    // MARK: - Progress Header
    private var progressHeader: some View {
        VStack(spacing: 12) {
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.accentColor)
                        .frame(width: geometry.size.width * scanningService.progress, height: 12)
                        .animation(.easeInOut, value: scanningService.progress)
                }
            }
            .frame(height: 12)
            
            // Progress Text
            HStack {
                Text("\(scanningService.scannedCount) von \(scanningService.totalMoles) gescannt")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(scanningService.progress * 100))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.accentColor)
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Current Mole View
    private func currentMoleView(_ mole: Mole) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Mole Info Card
                VStack(spacing: 16) {
                    // Position indicator
                    Text("Leberfleck \(scanningService.currentMoleIndex + 1) von \(scanningService.totalMoles)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Mole details
                    VStack(spacing: 8) {
                        Text(localizedRegion(for: mole))
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(localizedSide(for: mole))
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Latest image preview
                    if let latestImage = mole.latestImage,
                       let thumbnail = latestImage.thumbnailImage {
                        VStack(spacing: 8) {
                            Text("Letztes Foto:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Image(uiImage: thumbnail)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(radius: 4)
                            
                            Text(latestImage.captureDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Image count
                    Label("\(mole.imageCount) Fotos", systemImage: "photo.stack")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(radius: 2)
                
                // Action Buttons - MOVED UP
                VStack(spacing: 12) {
                    // Take Photo Button
                    Button(action: {
                        showingCamera = true
                    }) {
                        Label("Foto aufnehmen", systemImage: "camera.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isProcessingImage)
                    
                    // Skip Button
                    Button(action: {
                        scanningService.skipCurrent()
                    }) {
                        Label("Überspringen", systemImage: "forward.fill")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isProcessingImage)
                    
                    // Back Button (if not first)
                    if scanningService.currentMoleIndex > 0 {
                        Button(action: {
                            scanningService.goToPrevious()
                        }) {
                            Label("Zurück", systemImage: "arrow.left")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .foregroundColor(.secondary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(isProcessingImage)
                    }
                }
                
                // Processing indicator
                if isProcessingImage {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Bild wird verarbeitet...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                
                // Overview Images - NEW SECTION
                if !mole.locationMarkers.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Verknüpfte Übersichtsbilder:")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(mole.locationMarkers) { marker in
                                    if let overview = marker.overviewImage,
                                       let thumbnail = overview.thumbnailImage {
                                        VStack(spacing: 4) {
                                            ZStack(alignment: .center) {
                                                Image(uiImage: thumbnail)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 120, height: 120)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                                
                                                // Marker position indicator
                                                Circle()
                                                    .fill(Color.red)
                                                    .frame(width: 16, height: 16)
                                                    .overlay(
                                                        Circle()
                                                            .stroke(Color.white, lineWidth: 2)
                                                    )
                                                    .offset(
                                                        x: (marker.normalizedX - 0.5) * 120,
                                                        y: (marker.normalizedY - 0.5) * 120
                                                    )
                                            }
                                            
                                            Text(overview.captureDate.formatted(date: .abbreviated, time: .omitted))
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }
                                        .frame(width: 120)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 2)
                }
                
                // Instructions
                VStack(alignment: .leading, spacing: 12) {
                    Label("Anleitung", systemImage: "info.circle.fill")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        instructionRow(number: 1, text: "Positionieren Sie sich vor dem Leberfleck")
                        instructionRow(number: 2, text: "Nutzen Sie das Overlay zur Ausrichtung")
                        instructionRow(number: 3, text: "Nehmen Sie ein neues Foto auf")
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(radius: 2)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Completion View
    private var completionView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Scannen abgeschlossen!")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                Text("\(scanningService.scannedCount) Leberflecke gescannt")
                    .font(.headline)
                
                if scanningService.skippedMoles.count > 0 {
                    Text("\(scanningService.skippedMoles.count) übersprungen")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Button(action: {
                showingCompletionSheet = true
            }) {
                Text("Zusammenfassung anzeigen")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            
            Button(action: {
                dismiss()
            }) {
                Text("Fertig")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Completion Summary Sheet
    private var completionSummarySheet: some View {
        NavigationStack {
            List {
                Section("Statistik") {
                    LabeledContent("Gescannt", value: "\(scanningService.scannedCount)")
                    LabeledContent("Übersprungen", value: "\(scanningService.skippedMoles.count)")
                    LabeledContent("Gesamt", value: "\(scanningService.totalMoles)")
                }
                
                if scanningService.scannedCount > 0 {
                    Section("Gescannte Leberflecke") {
                        ForEach(moles.filter { scanningService.scannedMoles.contains($0.id) }) { mole in
                            HStack {
                                if let thumbnail = mole.latestImage?.thumbnailImage {
                                    Image(uiImage: thumbnail)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 50, height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(localizedRegion(for: mole))
                                        .font(.headline)
                                    Text(localizedSide(for: mole))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                
                if scanningService.skippedMoles.count > 0 {
                    Section("Übersprungene Leberflecke") {
                        ForEach(moles.filter { scanningService.skippedMoles.contains($0.id) }) { mole in
                            HStack {
                                if let thumbnail = mole.latestImage?.thumbnailImage {
                                    Image(uiImage: thumbnail)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 50, height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(localizedRegion(for: mole))
                                        .font(.headline)
                                    Text(localizedSide(for: mole))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Zusammenfassung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        showingCompletionSheet = false
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Views
    private func instructionRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 28, height: 28)
                
                Text("\(number)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.accentColor)
            }
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
    
    // MARK: - Helper Functions
    private func localizedRegion(for mole: Mole) -> String {
        if let region = BodyRegion.allCases.first(where: { $0.legacyRawValue == mole.bodyRegion || $0.rawValue == mole.bodyRegion }) {
            return region.localizedName
        }
        return mole.bodyRegion
    }
    
    private func localizedSide(for mole: Mole) -> String {
        if let region = BodyRegion.allCases.first(where: { $0.legacyRawValue == mole.bodyRegion || $0.rawValue == mole.bodyRegion }),
           let side = BodySide.availableSides(for: region).first(where: { $0.legacyRawValue == mole.bodySide || $0.rawValue == mole.bodySide }) {
            return side.displayText
        }
        return mole.bodySide
    }
    
    private func addImageToCurrentMole(_ uiImage: UIImage) {
        guard let mole = scanningService.currentMole else { return }
        
        isProcessingImage = true
        
        Task {
            guard let moleImage = await MoleImage.create(from: uiImage) else {
                await MainActor.run {
                    isProcessingImage = false
                }
                return
            }
            
            await MainActor.run {
                moleImage.mole = mole
                mole.images.append(moleImage)
                mole.updateModifiedDate()
                
                modelContext.insert(moleImage)
                
                // Mark as scanned and move to next
                scanningService.markCurrentAsScanned()
                
                isProcessingImage = false
            }
        }
    }
}

#Preview {
    GuidedScanningView(moles: [
        Mole(bodyRegion: "Kopf", bodySide: "Links"),
        Mole(bodyRegion: "Arm/Hand rechts", bodySide: "Oberarm-Vorne (Bizeps)")
    ])
    .modelContainer(for: [Mole.self, MoleImage.self], inMemory: true)
}