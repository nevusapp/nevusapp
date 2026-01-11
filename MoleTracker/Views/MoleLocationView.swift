//
//  MoleLocationView.swift
//  MoleTracker
//
//  Created on 11.01.2026.
//

import SwiftUI
import SwiftData

// MARK: - Image Size Preference Key
struct ImageSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// MARK: - Mole Location Management View
struct MoleLocationView: View {
    @Bindable var mole: Mole
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allOverviews: [BodyRegionOverview]
    @State private var selectedOverview: BodyRegionOverview?
    @State private var selectedMarker: MoleLocationMarker?
    @State private var isEditingExisting = false
    @State private var showingCamera = false
    @State private var isProcessingImage = false
    
    // Filter overviews for the mole's region
    private var regionOverviews: [BodyRegionOverview] {
        allOverviews.filter { overview in
            // Match by exact string or by BodyRegion enum
            let overviewRegion = BodyRegion.from(value: overview.bodyRegion)
            let moleRegion = BodyRegion.from(value: mole.bodyRegion)
            return overviewRegion == moleRegion
        }.sorted(by: { $0.captureDate > $1.captureDate })
    }
    
    var body: some View {
        List {
            // Linked Overview Images Section
            Section {
                if mole.locationMarkers.isEmpty {
                    emptyStateView
                } else {
                    ForEach(mole.locationMarkers) { marker in
                        if let overview = marker.overviewImage {
                            Button(action: {
                                selectedOverview = overview
                                selectedMarker = marker
                                isEditingExisting = true
                            }) {
                                LinkedOverviewRow(marker: marker, overview: overview)
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteMarker(marker)
                                } label: {
                                    Label(String(localized: "action_delete"), systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            } header: {
                Text(String(localized: "location_linked_overviews"))
            } footer: {
                Text(String(localized: "location_footer_description"))
                    .font(.caption)
            }
            
            // Available Overview Images Section
            Section {
                // Button to create new overview image
                Button(action: {
                    showingCamera = true
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                            .foregroundColor(.accentColor)
                        Text(String(localized: "location_create_overview"))
                            .foregroundColor(.primary)
                        Spacer()
                    }
                }
                .disabled(isProcessingImage)
                
                if !regionOverviews.isEmpty {
                    ForEach(regionOverviews) { overview in
                        let isLinked = mole.locationMarkers.contains { $0.overviewImage?.id == overview.id }
                        
                        Button(action: {
                            if !isLinked {
                                print("🔵 Selecting available overview: \(overview.id)")
                                selectedMarker = nil
                                isEditingExisting = false
                                selectedOverview = overview
                                print("🔵 selectedOverview set for new marker")
                            }
                        }) {
                            AvailableOverviewRow(overview: overview, isLinked: isLinked)
                        }
                        .buttonStyle(.plain)
                        .disabled(isLinked)
                    }
                }
            } header: {
                Text(String(localized: "location_available_overviews"))
            } footer: {
                if isProcessingImage {
                    HStack {
                        ProgressView()
                            .padding(.trailing, 8)
                        Text(String(localized: "image_being_processed"))
                            .font(.caption)
                    }
                }
            }
        }
        .navigationTitle(String(localized: "location_title"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingCamera) {
            CameraView(referenceImage: nil) { image in
                createOverviewImage(image)
            }
        }
        .sheet(item: $selectedOverview) { overview in
            let _ = print("🟢 Sheet opened for overview: \(overview.id), isEditingExisting = \(isEditingExisting)")
            // Always show MarkerPlacementView - it handles both new and existing markers
            NavigationStack {
                MarkerPlacementView(
                    mole: mole,
                    overview: overview,
                    existingMarker: selectedMarker,
                    onComplete: {
                        print("🟢 MarkerPlacement completed")
                        isEditingExisting = false
                        selectedOverview = nil
                        selectedMarker = nil
                    }
                )
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text(String(localized: "location_empty_title"))
                .font(.headline)
            
            Text(String(localized: "location_empty_message"))
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private func deleteMarker(_ marker: MoleLocationMarker) {
        modelContext.delete(marker)
        mole.updateModifiedDate()
    }
    
    private func createOverviewImage(_ uiImage: UIImage) {
        isProcessingImage = true
        
        Task {
            // Create overview on background thread
            let overview = await Task.detached {
                return BodyRegionOverview(bodyRegion: mole.bodyRegion, image: uiImage)
            }.value
            
            await MainActor.run {
                modelContext.insert(overview)
                
                // Automatically select the new overview for marker placement
                selectedMarker = nil
                isEditingExisting = false
                selectedOverview = overview
                
                isProcessingImage = false
            }
        }
    }
}

// MARK: - Linked Overview Row
struct LinkedOverviewRow: View {
    let marker: MoleLocationMarker
    let overview: BodyRegionOverview
    
    var body: some View {
        HStack(spacing: 12) {
            if let thumbnail = overview.thumbnailImage {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(alignment: .center) {
                        // Show marker position indicator
                        Circle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .offset(
                                x: (marker.normalizedX - 0.5) * 80,
                                y: (marker.normalizedY - 0.5) * 80
                            )
                    }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(overview.captureDate.formatted(date: .long, time: .omitted))
                    .font(.subheadline)
                
                Text(String(localized: "location_tap_to_view"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !marker.label.isEmpty {
                    Text(marker.label)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Available Overview Row
struct AvailableOverviewRow: View {
    let overview: BodyRegionOverview
    let isLinked: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            if let thumbnail = overview.thumbnailImage {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .opacity(isLinked ? 0.5 : 1.0)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(overview.captureDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .foregroundColor(isLinked ? .secondary : .primary)
                
                if isLinked {
                    Text(String(localized: "location_already_linked"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text(String(localized: "location_tap_to_link"))
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            if isLinked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Image(systemName: "plus.circle")
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Marker Placement View
struct MarkerPlacementView: View {
    @Bindable var mole: Mole
    @Bindable var overview: BodyRegionOverview
    let existingMarker: MoleLocationMarker?
    let onComplete: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var markerPosition: CGPoint?
    @State private var originalMarkerPosition: CGPoint?
    @State private var imageSize: CGSize = .zero
    @State private var label: String = ""
    // Store normalized coordinates immediately to prevent position shift
    @State private var normalizedX: Double?
    @State private var normalizedY: Double?
    
    init(mole: Mole, overview: BodyRegionOverview, existingMarker: MoleLocationMarker? = nil, onComplete: @escaping () -> Void) {
        self.mole = mole
        self.overview = overview
        self.existingMarker = existingMarker
        self.onComplete = onComplete
        _label = State(initialValue: existingMarker?.label ?? "")
        // Initialize normalized coordinates from existing marker
        if let existing = existingMarker {
            _normalizedX = State(initialValue: existing.normalizedX)
            _normalizedY = State(initialValue: existing.normalizedY)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Instructions
            VStack(spacing: 8) {
                Text(String(localized: "marker_placement_instruction"))
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                Text(String(localized: "marker_placement_hint"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(.ultraThinMaterial)
            
            // Image with tap gesture
            if let uiImage = overview.uiImage {
                GeometryReader { geometry in
                    let imageAspect = uiImage.size.width / uiImage.size.height
                    let frameAspect = geometry.size.width / geometry.size.height
                    
                    let calculatedSize: CGSize = {
                        if imageAspect > frameAspect {
                            // Image is wider - width fills, height is smaller
                            return CGSize(
                                width: geometry.size.width,
                                height: geometry.size.width / imageAspect
                            )
                        } else {
                            // Image is taller - height fills, width is smaller
                            return CGSize(
                                width: geometry.size.height * imageAspect,
                                height: geometry.size.height
                            )
                        }
                    }()
                    
                    ZStack(alignment: .topLeading) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                        
                        // Show original position (if editing existing marker)
                        if let originalPosition = originalMarkerPosition, existingMarker != nil {
                            Circle()
                                .fill(Color.gray.opacity(0.5))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                )
                                .position(originalPosition)
                                .shadow(radius: 3)
                        }
                        
                        // Show current/new position - recalculate from normalized coords
                        if let normX = normalizedX, let normY = normalizedY, calculatedSize.width > 0 {
                            let displayX = normX * calculatedSize.width
                            let displayY = normY * calculatedSize.height
                            Circle()
                                .fill(Color.red)
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 3)
                                )
                                .position(x: displayX, y: displayY)
                                .shadow(radius: 5)
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { value in
                                let location = value.location
                                // Store normalized coordinates immediately
                                if calculatedSize.width > 0 && calculatedSize.height > 0 {
                                    normalizedX = location.x / calculatedSize.width
                                    normalizedY = location.y / calculatedSize.height
                                    imageSize = calculatedSize
                                    print("📍 Tap at: \(location), normalized: (\(normalizedX!), \(normalizedY!)), imageSize: \(imageSize)")
                                }
                            }
                    )
                    .onAppear {
                        // Set image size first
                        imageSize = calculatedSize
                        print("📐 Image size calculated on appear: \(imageSize)")
                        
                        // If editing existing marker, calculate original position for display
                        if let existing = existingMarker, calculatedSize.width > 0 {
                            let x = existing.normalizedX * calculatedSize.width
                            let y = existing.normalizedY * calculatedSize.height
                            originalMarkerPosition = CGPoint(x: x, y: y)
                            print("📍 Loaded existing marker at: (\(x), \(y)) from normalized (\(existing.normalizedX), \(existing.normalizedY))")
                        }
                    }
                    .onChange(of: calculatedSize) { oldSize, newSize in
                        // Update image size and recalculate positions
                        imageSize = newSize
                        if let existing = existingMarker, newSize.width > 0 {
                            let x = existing.normalizedX * newSize.width
                            let y = existing.normalizedY * newSize.height
                            originalMarkerPosition = CGPoint(x: x, y: y)
                            print("📍 Recalculated original position for new size: \(newSize)")
                        }
                    }
                }
            }
            
            // Label input and save button - always show to prevent layout shift
            VStack(spacing: 12) {
                TextField(String(localized: "marker_label_placeholder"), text: $label)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
                Button(action: saveMarker) {
                    Text(String(localized: "marker_save_action"))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                .disabled(normalizedX == nil || normalizedY == nil)
                .opacity((normalizedX == nil || normalizedY == nil) ? 0.5 : 1.0)
            }
            .padding(.vertical)
            .background(.ultraThinMaterial)
        }
        .navigationTitle(String(localized: "marker_placement_title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(String(localized: "action_cancel")) {
                    dismiss()
                    onComplete()
                }
            }
        }
    }
    
    private func saveMarker() {
        guard let normX = normalizedX, let normY = normalizedY else {
            print("❌ No marker position set")
            return
        }
        
        print("✅ Saving marker with normalized coordinates: x=\(normX), y=\(normY)")
        
        if let existing = existingMarker {
            // Update existing marker
            existing.normalizedX = normX
            existing.normalizedY = normY
            existing.label = label
            print("✅ Updated existing marker")
        } else {
            // Create new marker
            let marker = MoleLocationMarker(
                normalizedX: normX,
                normalizedY: normY,
                label: label
            )
            
            // Link relationships
            marker.mole = mole
            marker.overviewImage = overview
            
            mole.locationMarkers.append(marker)
            overview.locationMarkers.append(marker)
            
            modelContext.insert(marker)
            print("✅ Created new marker")
        }
        
        mole.updateModifiedDate()
        
        dismiss()
        onComplete()
    }
}

// MARK: - Overview with Marker View
struct OverviewWithMarkerView: View {
    let overview: BodyRegionOverview
    let mole: Mole
    
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var imageSize: CGSize = .zero
    
    // Find marker for this mole on this overview
    private var marker: MoleLocationMarker? {
        mole.locationMarkers.first { $0.overviewImage?.id == overview.id }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Image with zoom and pan
            GeometryReader { geometry in
                if let uiImage = overview.uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .overlay {
                            if let marker = marker {
                                // Calculate marker position
                                let markerX = marker.normalizedX * imageSize.width
                                let markerY = marker.normalizedY * imageSize.height
                                
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 30 / scale, height: 30 / scale)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 3 / scale)
                                    )
                                    .position(x: markerX, y: markerY)
                                    .shadow(radius: 5 / scale)
                            }
                        }
                        .background(
                            GeometryReader { imageGeometry in
                                Color.clear
                                    .onAppear {
                                        imageSize = imageGeometry.size
                                    }
                                    .onChange(of: imageGeometry.size) { _, newSize in
                                        imageSize = newSize
                                    }
                            }
                        )
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    scale = min(max(scale * delta, 1.0), 5.0)
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                }
                        )
                        .simultaneousGesture(
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                }
            }
            
            // Info panel
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("\(String(localized: "label_captured")):")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(overview.captureDate.formatted(date: .long, time: .shortened))
                        .font(.caption)
                }
                
                if let marker = marker, !marker.label.isEmpty {
                    HStack {
                        Text("\(String(localized: "marker_label")):")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(marker.label)
                            .font(.caption)
                    }
                }
                
                // Zoom controls
                HStack {
                    Button(action: { resetZoom() }) {
                        Label(String(localized: "zoom_reset"), systemImage: "arrow.up.left.and.arrow.down.right")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Text(String(localized: "zoom_level", defaultValue: "Zoom: \(Int(scale * 100))%", comment: "Current zoom level"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.ultraThinMaterial)
        }
        .navigationTitle(String(localized: "location_overview_title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(String(localized: "action_done")) {
                    dismiss()
                }
            }
        }
    }
    
    private func resetZoom() {
        withAnimation(.spring()) {
            scale = 1.0
            lastScale = 1.0
            offset = .zero
            lastOffset = .zero
        }
    }
}

#Preview {
    NavigationStack {
        MoleLocationView(mole: Mole(bodyRegion: "Kopf", bodySide: "Links"))
            .modelContainer(for: [Mole.self, MoleImage.self, BodyRegionOverview.self, MoleLocationMarker.self], inMemory: true)
    }
}