//
//  RegionOverviewView.swift
//  MoleTracker
//
//  Created on 11.01.2026.
//

import SwiftUI
import SwiftData

struct RegionOverviewView: View {
    let region: BodyRegion
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var overviews: [BodyRegionOverview]
    @State private var showingCamera = false
    @State private var selectedOverview: BodyRegionOverview?
    @State private var showingImageDetail = false
    
    init(region: BodyRegion) {
        self.region = region
        // Filter overviews for this region - use legacyRawValue for backward compatibility
        let regionName = region.legacyRawValue
        _overviews = Query(
            filter: #Predicate<BodyRegionOverview> { overview in
                overview.bodyRegion == regionName
            },
            sort: \BodyRegionOverview.captureDate,
            order: .reverse
        )
    }
    
    var body: some View {
        List {
            Section {
                if overviews.isEmpty {
                    emptyStateView
                } else {
                    overviewsGridView
                }
            } header: {
                Text(String(localized: "overview_images"))
            } footer: {
                Text(String(localized: "overview_footer_description", defaultValue: "Capture overview images showing all moles in this region simultaneously.", comment: "Footer text for overview images section"))
                    .font(.caption)
            }
        }
        .navigationTitle(region.localizedName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingCamera = true }) {
                    Label(String(localized: "action_take_photo"), systemImage: "camera.fill")
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraView { image in
                addOverviewImage(image)
            }
        }
        .sheet(item: $selectedOverview) { overview in
            NavigationStack {
                OverviewImageDetailView(overview: overview)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(String(localized: "empty_overview_title", defaultValue: "No Overview Images", comment: "Empty state title for overview images"))
                .font(.headline)
            
            Text(String(localized: "empty_overview_message", defaultValue: "Tap the camera icon to capture an overview image", comment: "Empty state message for overview images"))
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var overviewsGridView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            ForEach(overviews) { overview in
                Button(action: {
                    selectedOverview = overview
                }) {
                    VStack(alignment: .leading, spacing: 4) {
                        if let thumbnail = overview.thumbnailImage {
                            Image(uiImage: thumbnail)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 150)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 150)
                        }
                        
                        Text(overview.captureDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button(role: .destructive) {
                        deleteOverview(overview)
                    } label: {
                        Label(String(localized: "action_delete"), systemImage: "trash")
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func addOverviewImage(_ image: UIImage) {
        let overview = BodyRegionOverview(bodyRegion: region.legacyRawValue, image: image)
        
        // Note: Sensor data collection could be added in future
        // For now, initialize with default values
        overview.updateSensorData(
            pitch: 0,
            roll: 0,
            yaw: 0,
            pressure: nil,
            altitude: nil
        )
        
        modelContext.insert(overview)
    }
    
    private func deleteOverview(_ overview: BodyRegionOverview) {
        modelContext.delete(overview)
    }
}

// MARK: - Overview Image Detail View
struct OverviewImageDetailView: View {
    @Bindable var overview: BodyRegionOverview
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var isEditingNotes = false
    @State private var showingDeleteConfirmation = false
    @State private var showMoleMarkers = true
    @State private var selectedMole: Mole?
    
    var body: some View {
        VStack(spacing: 0) {
            // Image with zoom and mole markers
            if let uiImage = overview.uiImage {
                GeometryReader { geometry in
                    ZStack {
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
                        
                        // Mole location markers overlay
                        if showMoleMarkers {
                            ForEach(overview.locationMarkers) { marker in
                                Button(action: {
                                    if let mole = marker.mole {
                                        selectedMole = mole
                                    }
                                }) {
                                    MoleMarkerView(marker: marker)
                                }
                                .buttonStyle(.plain)
                                .position(
                                    x: geometry.size.width * marker.normalizedX,
                                    y: geometry.size.height * marker.normalizedY
                                )
                                .scaleEffect(scale)
                            }
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
                .aspectRatio(uiImage.size.width / uiImage.size.height, contentMode: .fit)
            }
            
            // Image info
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("\(String(localized: "label_captured")):")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(overview.captureDate.formatted(date: .long, time: .shortened))
                        .font(.caption)
                }
                
                // Notes section
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(String(localized: "section_notes")):")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if isEditingNotes {
                        TextEditor(text: $overview.notes)
                            .frame(height: 80)
                            .padding(4)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Text(overview.notes.isEmpty ? String(localized: "label_no_notes") : overview.notes)
                            .font(.body)
                            .foregroundColor(overview.notes.isEmpty ? .secondary : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .onTapGesture {
                                isEditingNotes = true
                            }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.ultraThinMaterial)
        }
        .navigationTitle(String(localized: "overview_image_title", defaultValue: "Overview Image", comment: "Title for overview image detail view"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if !overview.locationMarkers.isEmpty {
                    Button(action: { showMoleMarkers.toggle() }) {
                        Label(
                            showMoleMarkers ? String(localized: "hide_mole_markers", defaultValue: "Hide Markers", comment: "Hide mole markers button") : String(localized: "show_mole_markers", defaultValue: "Show Markers", comment: "Show mole markers button"),
                            systemImage: showMoleMarkers ? "eye.slash.fill" : "eye.fill"
                        )
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(isEditingNotes ? String(localized: "action_done") : String(localized: "action_edit", defaultValue: "Edit", comment: "Edit button")) {
                        isEditingNotes.toggle()
                    }
                    
                    Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                        Label(String(localized: "action_delete"), systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert(String(localized: "delete_overview_title", defaultValue: "Delete Overview Image?", comment: "Delete confirmation title"), isPresented: $showingDeleteConfirmation) {
            Button(String(localized: "action_cancel"), role: .cancel) { }
            Button(String(localized: "action_delete"), role: .destructive) {
                deleteOverview()
            }
        } message: {
            Text(String(localized: "delete_overview_message", defaultValue: "Do you really want to delete this overview image? This action cannot be undone.", comment: "Delete confirmation message"))
        }
        .navigationDestination(item: $selectedMole) { mole in
            MoleDetailView(mole: mole)
        }
    }
    
    private func deleteOverview() {
        modelContext.delete(overview)
        dismiss()
    }
}

// MARK: - Mole Marker View
struct MoleMarkerView: View {
    let marker: MoleLocationMarker
    
    var body: some View {
        ZStack {
            // Outer circle (white border)
            Circle()
                .stroke(Color.white, lineWidth: 3)
                .frame(width: 30, height: 30)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            
            // Inner circle (colored fill)
            Circle()
                .fill(Color.red.opacity(0.7))
                .frame(width: 24, height: 24)
            
            // Center dot
            Circle()
                .fill(Color.white)
                .frame(width: 6, height: 6)
        }
    }
}

#Preview {
    NavigationStack {
        RegionOverviewView(region: .head)
            .modelContainer(for: [BodyRegionOverview.self], inMemory: true)
    }
}