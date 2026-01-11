//
//  MoleDetailView.swift
//  MoleTracker
//
//  Created on 06.01.2026.
//

import SwiftUI
import SwiftData

struct MoleDetailView: View {
    @Bindable var mole: Mole
    @Environment(\.modelContext) private var modelContext
    @State private var showingCamera = false
    @State private var showingComparison = false
    @State private var selectedImageForComparison: MoleImage?
    @State private var isEditingNotes = false
    @State private var selectedRegion: BodyRegion
    @State private var selectedSide: BodySide
    @State private var selectedImageForDetail: MoleImage?
    @State private var isProcessingImage = false
    @State private var exportURL: URL?
    @State private var isExporting = false
    
    init(mole: Mole) {
        self.mole = mole
        _selectedRegion = State(initialValue: BodyRegion.allCases.first { $0.rawValue == mole.bodyRegion } ?? .head)
        _selectedSide = State(initialValue: BodySide.allCases.first { $0.rawValue == mole.bodySide } ?? .center)
    }
    
    var body: some View {
        List {
            // Images Section
            Section {
                if isProcessingImage {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Bild wird verarbeitet...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 20)
                        Spacer()
                    }
                } else if mole.images.isEmpty {
                    emptyImagesView
                } else {
                    imagesGridView
                }
            } header: {
                HStack {
                    Text("Bilder (\(mole.imageCount))")
                    Spacer()
                    Button(action: { showingCamera = true }) {
                        Label("Foto", systemImage: "camera.fill")
                            .font(.caption)
                    }
                    .disabled(isProcessingImage)
                }
            }
            
            // Notes Section
            Section("Notizen") {
                if isEditingNotes {
                    TextEditor(text: $mole.notes)
                        .frame(minHeight: 100)
                } else {
                    if mole.notes.isEmpty {
                        Text("Keine Notizen")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        Text(mole.notes)
                    }
                }
            }
            .onTapGesture {
                isEditingNotes.toggle()
            }
            
            // Details Section
            Section("Details") {
                Picker("Region", selection: $selectedRegion) {
                    ForEach(BodyRegion.allCases) { region in
                        Text(region.rawValue).tag(region)
                    }
                }
                .onChange(of: selectedRegion) { _, newValue in
                    mole.bodyRegion = newValue.rawValue
                    mole.updateModifiedDate()
                }
                
                Picker("Seite", selection: $selectedSide) {
                    ForEach(BodySide.allCases) { side in
                        Text(side.rawValue).tag(side)
                    }
                }
                .onChange(of: selectedSide) { _, newValue in
                    mole.bodySide = newValue.rawValue
                    mole.updateModifiedDate()
                }
                
                LabeledContent("Erstellt", value: mole.createdAt.formatted(date: .long, time: .shortened))
                LabeledContent("Zuletzt geändert", value: mole.lastModified.formatted(date: .long, time: .shortened))
            }
            
            // Reference Image Section
            if mole.images.count >= 1 {
                Section {
                    if let refImage = mole.referenceImage {
                        HStack {
                            if let thumbnail = refImage.thumbnailImage {
                                Image(uiImage: thumbnail)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Referenzbild für Overlay")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(refImage.captureDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if mole.referenceImageID != nil {
                                Button("Zurücksetzen") {
                                    mole.clearReferenceImage()
                                }
                                .font(.caption)
                            }
                        }
                    }
                    
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
            }
            
            // Comparison Section
            if mole.images.count >= 2 {
                Section("Vergleich") {
                    Button(action: { showingComparison = true }) {
                        Label("Bilder vergleichen", systemImage: "arrow.left.and.right.square")
                    }
                }
            }
        }
        .navigationTitle("Leberfleck Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { exportMole() }) {
                        Label("Exportieren", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .disabled(isExporting)
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(referenceImage: mole.referenceImage?.uiImage) { image in
                addImage(image)
            }
        }
        .sheet(isPresented: $showingComparison) {
            NavigationStack {
                ComparisonSelectionView(mole: mole)
            }
        }
        .sheet(item: $exportURL) { url in
            ShareSheet(items: [url])
        }
        .overlay {
            if isExporting {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Exportiere Leberfleck...")
                            .font(.headline)
                    }
                    .padding(32)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }
    
    private var emptyImagesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("Noch keine Bilder")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: { showingCamera = true }) {
                Label("Erstes Foto aufnehmen", systemImage: "camera.fill")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var imagesGridView: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            LazyHGrid(rows: [
                GridItem(.fixed(100), spacing: 12),
                GridItem(.fixed(100), spacing: 12)
            ], spacing: 12) {
                ForEach(mole.images.sorted(by: { $0.captureDate > $1.captureDate }), id: \.id) { image in
                    Button(action: {
                        selectedImageForDetail = image
                    }) {
                        ZStack(alignment: .topLeading) {
                            if let thumbnail = image.thumbnailImage {
                                Image(uiImage: thumbnail)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(alignment: .bottomTrailing) {
                                        Text(image.captureDate.formatted(date: .abbreviated, time: .omitted))
                                            .font(.caption2)
                                            .padding(4)
                                            .background(.ultraThinMaterial)
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                            .padding(4)
                                    }
                            }
                            
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
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 8)
        }
        .frame(height: 224) // Fixed height for 2 rows: (100 + 12) * 2
        .sheet(item: $selectedImageForDetail) { image in
            NavigationStack {
                ImageDetailView(image: image)
            }
        }
    }
    
    // private func addImage(_ uiImage: UIImage) {
    //     // Show loading indicator
    //     isProcessingImage = true
        
    //     // Create image asynchronously to avoid blocking UI
    //     Task {
    //         guard let moleImage = await MoleImage.create(from: uiImage) else {
    //             await MainActor.run {
    //                 isProcessingImage = false
    //             }
    //             return
    //         }
            
    //         await MainActor.run {
    //             moleImage.mole = mole
    //             mole.images.append(moleImage)
    //             mole.updateModifiedDate()
                
    //             modelContext.insert(moleImage)
                
    //             // Hide loading indicator
    //             isProcessingImage = false
    //         }
    //     }
    // }
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
    
    private func exportMole() {
        isExporting = true
        
        Task.detached(priority: .userInitiated) {
            if let url = ExportService.exportMole(mole) {
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
}

// MARK: - Image Detail View
struct ImageDetailView: View {
    let image: MoleImage
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var showingComparison = false
    @State private var exportURL: URL?
    @State private var isExporting = false
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Image with zoom
            if let uiImage = image.uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = lastScale * value
                            }
                            .onEnded { _ in
                                lastScale = scale
                            }
                    )
            }
            
            // Image info
            VStack(alignment: .leading, spacing: 8) {
                Text("Aufgenommen: \(image.captureDate.formatted(date: .long, time: .shortened))")
                    .font(.caption)
                Text("Auflösung: \(image.imageWidth) × \(image.imageHeight)")
                    .font(.caption)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.ultraThinMaterial)
            
            // Compare button (only show if mole has more than 1 image)
            if let mole = image.mole, mole.images.count >= 2 {
                Button(action: { showingComparison = true }) {
                    Label("Mit anderem Bild vergleichen", systemImage: "arrow.left.and.right.square")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
            }
        }
        .navigationTitle("Bild")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: exportImage) {
                        Label("Teilen", systemImage: "square.and.arrow.up")
                    }
                    .disabled(isExporting)
                    
                    Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                        Label("Löschen", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Bild löschen?", isPresented: $showingDeleteConfirmation) {
            Button("Abbrechen", role: .cancel) { }
            Button("Löschen", role: .destructive) {
                deleteImage()
            }
        } message: {
            Text("Möchten Sie dieses Bild wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.")
        }
        .sheet(isPresented: $showingComparison) {
            if let mole = image.mole {
                NavigationStack {
                    ComparisonSelectionView(mole: mole, preselectedImage: image)
                }
            }
        }
        .sheet(item: $exportURL) { url in
            ShareSheet(items: [url])
        }
    }
    
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
    
    private func deleteImage() {
        if let mole = image.mole {
            mole.updateModifiedDate()
        }
        modelContext.delete(image)
        dismiss()
    }
}

// MARK: - Comparison Selection View
struct ComparisonSelectionView: View {
    let mole: Mole
    let preselectedImage: MoleImage?
    @Environment(\.dismiss) private var dismiss
    @State private var selectedImage1: MoleImage?
    @State private var selectedImage2: MoleImage?
    
    init(mole: Mole, preselectedImage: MoleImage? = nil) {
        self.mole = mole
        self.preselectedImage = preselectedImage
        _selectedImage1 = State(initialValue: preselectedImage)
    }
    
    var sortedImages: [MoleImage] {
        mole.images.sorted(by: { $0.captureDate > $1.captureDate })
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Single list with numbered selection
            List {
                Section("Zwei Bilder zum Vergleichen auswählen") {
                    ForEach(sortedImages) { image in
                        ImageSelectionRow(
                            image: image,
                            selectionNumber: getSelectionNumber(for: image)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            handleImageSelection(image)
                        }
                    }
                }
            }
            
            // Compare button
            if selectedImage1 != nil && selectedImage2 != nil {
                NavigationLink(destination: ComparisonView(image1: selectedImage1!, image2: selectedImage2!)) {
                    Text("Bilder vergleichen")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
            }
        }
        .navigationTitle("Bilder auswählen")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Fertig") {
                    dismiss()
                }
            }
        }
    }
    
    private func getSelectionNumber(for image: MoleImage) -> Int? {
        if selectedImage1?.id == image.id {
            return 1
        } else if selectedImage2?.id == image.id {
            return 2
        }
        return nil
    }
    
    private func handleImageSelection(_ image: MoleImage) {
        // If already selected as first image, deselect it
        if selectedImage1?.id == image.id {
            selectedImage1 = nil
            return
        }
        
        // If already selected as second image, deselect it
        if selectedImage2?.id == image.id {
            selectedImage2 = nil
            return
        }
        
        // Select as first or second image
        if selectedImage1 == nil {
            selectedImage1 = image
        } else if selectedImage2 == nil {
            selectedImage2 = image
        } else {
            // Both slots filled, replace first selection
            selectedImage1 = selectedImage2
            selectedImage2 = image
        }
    }
}

// MARK: - Image Selection Row
struct ImageSelectionRow: View {
    let image: MoleImage
    let selectionNumber: Int?
    
    var body: some View {
        HStack(spacing: 12) {
            if let thumbnail = image.thumbnailImage {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(image.captureDate.formatted(date: .long, time: .omitted))
                    .font(.headline)
                Text(image.captureDate.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let number = selectionNumber {
                ZStack {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 32, height: 32)
                    
                    Text("\(number)")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Reference Image Selection View
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
                            // Thumbnail
                            if let thumbnail = image.thumbnailImage {
                                Image(uiImage: thumbnail)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            
                            // Info
                            VStack(alignment: .leading, spacing: 4) {
                                Text(image.captureDate.formatted(date: .long, time: .shortened))
                                    .font(.subheadline)
                                
                                if sortedImages.first?.id == image.id {
                                    Text("Erste Aufnahme (Standard)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text("\(image.imageWidth) × \(image.imageHeight)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Selection indicator
                            if mole.referenceImage?.id == image.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                                    .font(.title2)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Wähle ein Referenzbild")
            } footer: {
                Text("Das ausgewählte Bild wird beim Fotografieren als halbtransparentes Overlay angezeigt. Die erste Aufnahme ist standardmäßig ausgewählt für langfristige Vergleichbarkeit.")
                    .font(.caption)
            }
        }
        .navigationTitle("Referenzbild")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Fertig") {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        MoleDetailView(mole: Mole(bodyRegion: "Kopf", bodySide: "Links"))
            .modelContainer(for: [Mole.self, MoleImage.self], inMemory: true)
    }
}