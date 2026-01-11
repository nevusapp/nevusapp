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
        // Filter overviews for this region
        let regionName = region.rawValue
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
                Text("Übersichtsbilder")
            } footer: {
                Text("Erfassen Sie Übersichtsbilder, in denen alle Leberflecke dieser Region gleichzeitig sichtbar sind.")
                    .font(.caption)
            }
        }
        .navigationTitle(region.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingCamera = true }) {
                    Label("Foto aufnehmen", systemImage: "camera.fill")
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
            
            Text("Keine Übersichtsbilder")
                .font(.headline)
            
            Text("Tippen Sie auf das Kamera-Symbol, um ein Übersichtsbild zu erfassen")
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
                        Label("Löschen", systemImage: "trash")
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func addOverviewImage(_ image: UIImage) {
        let overview = BodyRegionOverview(bodyRegion: region.rawValue, image: image)
        
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
    
    var body: some View {
        VStack(spacing: 0) {
            // Image with zoom
            if let uiImage = overview.uiImage {
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
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Aufgenommen:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(overview.captureDate.formatted(date: .long, time: .shortened))
                        .font(.caption)
                }
                
                // Notes section
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notizen:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if isEditingNotes {
                        TextEditor(text: $overview.notes)
                            .frame(height: 80)
                            .padding(4)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Text(overview.notes.isEmpty ? "Keine Notizen" : overview.notes)
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
        .navigationTitle("Übersichtsbild")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(isEditingNotes ? "Fertig" : "Bearbeiten") {
                        isEditingNotes.toggle()
                    }
                    
                    Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                        Label("Löschen", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Übersichtsbild löschen?", isPresented: $showingDeleteConfirmation) {
            Button("Abbrechen", role: .cancel) { }
            Button("Löschen", role: .destructive) {
                deleteOverview()
            }
        } message: {
            Text("Möchten Sie dieses Übersichtsbild wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.")
        }
    }
    
    private func deleteOverview() {
        modelContext.delete(overview)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        RegionOverviewView(region: .head)
            .modelContainer(for: [BodyRegionOverview.self], inMemory: true)
    }
}