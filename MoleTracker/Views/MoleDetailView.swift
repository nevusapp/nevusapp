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
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
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
    @State private var showingDeleteConfirmation = false
    
    // iPad detection
    private var isIPad: Bool {
        horizontalSizeClass == .regular
    }
    
    init(mole: Mole) {
        self.mole = mole
        let region = BodyRegion.from(value: mole.bodyRegion)
        _selectedRegion = State(initialValue: region)
        
        // Find matching side or use default for region
        let matchingSide = BodySide.from(value: mole.bodySide)
        _selectedSide = State(initialValue: matchingSide ?? BodySide.defaultSide(for: region))
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
                            Text(String(localized: "image_being_processed"))
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
                Text(String(localized: "section_images_count", defaultValue: "Images (\(mole.imageCount))", comment: "Section header with image count"))
            }
            
            // Notes Section
            Section(String(localized: "section_notes")) {
                if isEditingNotes {
                    TextEditor(text: $mole.notes)
                        .frame(minHeight: 100)
                } else {
                    ZStack(alignment: .topLeading) {
                        // Invisible background to make entire area tappable
                        Color.clear
                            .frame(minHeight: 60)
                        
                        if mole.notes.isEmpty {
                            Text(String(localized: "label_no_notes"))
                                .foregroundColor(.secondary)
                                .italic()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text(mole.notes)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isEditingNotes.toggle()
                    }
                }
            }
            
            // Location on Overview Section
            Section {
                if mole.locationMarkers.isEmpty {
                    // Show link to add location markers when none exist
                    NavigationLink(destination: MoleLocationView(mole: mole)) {
                        Label(String(localized: "location_manage_action"), systemImage: "mappin.and.ellipse")
                    }
                } else {
                    // Show thumbnails of linked overview images
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(mole.locationMarkers) { marker in
                                if let overview = marker.overviewImage {
                                    NavigationLink(destination: MoleLocationView(mole: mole)) {
                                        VStack(spacing: 4) {
                                            if let thumbnail = overview.thumbnailImage {
                                                ZStack(alignment: .center) {
                                                    Image(uiImage: thumbnail)
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: 100, height: 100)
                                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                                    
                                                    // Show marker position indicator
                                                    Circle()
                                                        .fill(Color.red)
                                                        .frame(width: 12, height: 12)
                                                        .overlay(
                                                            Circle()
                                                                .stroke(Color.white, lineWidth: 2)
                                                        )
                                                        .offset(
                                                            x: (marker.normalizedX - 0.5) * 100,
                                                            y: (marker.normalizedY - 0.5) * 100
                                                        )
                                                }
                                            }
                                            
                                            Text(overview.captureDate.formatted(date: .abbreviated, time: .omitted))
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }
                                        .frame(width: 100)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            
                            // Add button to link more overviews
                            NavigationLink(destination: MoleLocationView(mole: mole)) {
                                VStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.accentColor)
                                    
                                    Text(String(localized: "location_add_more"))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .frame(width: 100, height: 100)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 8)
                    }
                }
            } header: {
                Text(String(localized: "section_location_overview"))
            } footer: {
                Text(String(localized: "location_section_footer"))
                    .font(.caption)
            }
            
            // Details Section
            Section(String(localized: "section_details")) {
                Picker(String(localized: "label_region"), selection: $selectedRegion) {
                    ForEach(BodyRegion.allCases) { region in
                        Text(region.localizedName).tag(region)
                    }
                }
                .onChange(of: selectedRegion) { _, newValue in
                    mole.bodyRegion = newValue.rawValue
                    
                    // Update available sides for new region
                    let availableSides = BodySide.availableSides(for: newValue)
                    
                    // If current side is not available for new region, use default
                    if !availableSides.contains(selectedSide) {
                        selectedSide = BodySide.defaultSide(for: newValue)
                    }
                    
                    mole.updateModifiedDate()
                }
                
                Picker(String(localized: "label_side"), selection: $selectedSide) {
                    ForEach(BodySide.availableSides(for: selectedRegion)) { side in
                        Text(side.displayText).tag(side)
                    }
                }
                .onChange(of: selectedSide) { _, newValue in
                    mole.bodySide = newValue.rawValue
                    mole.updateModifiedDate()
                }
                
                LabeledContent(String(localized: "label_created"), value: mole.createdAt.formatted(date: .long, time: .shortened))
                LabeledContent(String(localized: "label_last_modified"), value: mole.lastModified.formatted(date: .long, time: .shortened))
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
                                Text(String(localized: "overlay_reference_for"))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(refImage.captureDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if mole.referenceImageID != nil {
                                Button(String(localized: "reference_reset_action")) {
                                    mole.clearReferenceImage()
                                }
                                .font(.caption)
                            }
                        }
                    }
                    
                    if mole.images.count >= 2 {
                        NavigationLink(destination: ReferenceImageSelectionView(mole: mole)) {
                            Label(String(localized: "reference_change_action"), systemImage: "photo.on.rectangle.angled")
                        }
                    }
                } header: {
                    Text(String(localized: "section_overlay_settings"))
                } footer: {
                    Text(String(localized: "overlay_footer_text"))
                        .font(.caption)
                }
            }
            
            // Comparison Section
            if mole.images.count >= 2 {
                Section(String(localized: "section_comparison")) {
                    Button(action: { showingComparison = true }) {
                        Label(String(localized: "action_compare"), systemImage: "arrow.left.and.right.square")
                    }
                }
            }
        }
        .navigationTitle(String(localized: "title_mole_detail"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingCamera = true }) {
                    Label(String(localized: "label_photo"), systemImage: "camera.fill")
                }
                .disabled(isProcessingImage)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { exportMole() }) {
                        Label(String(localized: "action_export"), systemImage: "square.and.arrow.up")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                        Label(String(localized: "mole_delete_action"), systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .disabled(isExporting)
            }
        }
        .alert(String(localized: "delete_title_mole"), isPresented: $showingDeleteConfirmation) {
            Button(String(localized: "action_cancel"), role: .cancel) { }
            Button(String(localized: "action_delete"), role: .destructive) {
                deleteMole()
            }
        } message: {
            Text(String(localized: "delete_confirmation_mole", defaultValue: "Do you really want to delete this mole with all \(mole.imageCount) images? This action cannot be undone.", comment: "Delete confirmation message with image count"))
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
                        Text(String(localized: "exporting_mole"))
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
            
            Text(String(localized: "empty_images_message"))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: { showingCamera = true }) {
                Label(String(localized: "take_first_photo"), systemImage: "camera.fill")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var imagesGridView: some View {
        Group {
            if isIPad {
                // iPad: Vertical grid with 3-4 columns
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
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
                                        .frame(height: 120)
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
            } else {
                // iPhone: Horizontal scroll with 2 rows
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
            }
        }
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
        
        Task(priority: .userInitiated) {
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
    
    private func deleteMole() {
        modelContext.delete(mole)
        dismiss()
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
                Text("\(String(localized: "label_captured")): \(image.captureDate.formatted(date: .long, time: .shortened))")
                    .font(.caption)
                Text("\(String(localized: "label_resolution")): \(image.imageWidth) × \(image.imageHeight)")
                    .font(.caption)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.ultraThinMaterial)
            
            // Compare button (only show if mole has more than 1 image)
            if let mole = image.mole, mole.images.count >= 2 {
                Button(action: { showingComparison = true }) {
                    Label(String(localized: "label_compare_with_other"), systemImage: "arrow.left.and.right.square")
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
        .navigationTitle(String(localized: "title_image"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: exportImage) {
                        Label(String(localized: "action_share"), systemImage: "square.and.arrow.up")
                    }
                    .disabled(isExporting)
                    
                    Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                        Label(String(localized: "action_delete"), systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert(String(localized: "delete_title_image"), isPresented: $showingDeleteConfirmation) {
            Button(String(localized: "action_cancel"), role: .cancel) { }
            Button(String(localized: "action_delete"), role: .destructive) {
                deleteImage()
            }
        } message: {
            Text(String(localized: "delete_confirmation_image"))
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
        
        Task(priority: .userInitiated) {
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
                Section(String(localized: "select_two_images")) {
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
                // Ensure older image is passed as image1, newer as image2
                let olderImage = selectedImage1!.captureDate < selectedImage2!.captureDate ? selectedImage1! : selectedImage2!
                let newerImage = selectedImage1!.captureDate < selectedImage2!.captureDate ? selectedImage2! : selectedImage1!
                
                NavigationLink(destination: ComparisonView(image1: olderImage, image2: newerImage)) {
                    Text(String(localized: "action_compare"))
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
        .navigationTitle(String(localized: "title_select_images"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(String(localized: "action_done")) {
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
                                    Text(String(localized: "reference_first_capture"))
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
                Text(String(localized: "reference_select_header"))
            } footer: {
                Text(String(localized: "reference_footer_text"))
                    .font(.caption)
            }
        }
        .navigationTitle(String(localized: "title_reference_image"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(String(localized: "action_done")) {
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
