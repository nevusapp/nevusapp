//
//  ContentView.swift
//  MoleTracker
//
//  Created on 06.01.2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var moles: [Mole]
    @Query(sort: \BodyRegionOverview.captureDate, order: .reverse)
    private var allOverviews: [BodyRegionOverview]
    @State private var showingAddMole = false
    @State private var showingCamera = false
    @State private var selectedMole: Mole?
    @State private var newlyCreatedMole: Mole?
    @State private var showingExportSheet = false
    @State private var exportURL: URL?
    @State private var isExporting = false
    @State private var selectedOverview: BodyRegionOverview?
    @State private var showingCleanup = false
    @State private var moleToDelete: Mole?
    @State private var showingDeleteConfirmation = false
    @State private var showingGuidedScanning = false
    @State private var showingGuidedComparison = false
    
    // Group moles by body region
    var groupedMoles: [(region: BodyRegion, moles: [Mole])] {
        let grouped = Dictionary(grouping: moles) { mole -> BodyRegion in
            // Try to match by legacy rawValue for backward compatibility
            BodyRegion.allCases.first { $0.legacyRawValue == mole.bodyRegion } ??
            BodyRegion.allCases.first { $0.rawValue == mole.bodyRegion } ?? .head
        }
        
        return BodyRegion.displayOrder.compactMap { region in
            guard let molesInRegion = grouped[region], !molesInRegion.isEmpty else { return nil }
            let sortedMoles = molesInRegion.sorted { $0.lastModified > $1.lastModified }
            return (region: region, moles: sortedMoles)
        }
    }
    
    // Get overviews for a specific region
    func overviews(for region: BodyRegion) -> [BodyRegionOverview] {
        allOverviews.filter { $0.bodyRegion == region.legacyRawValue || $0.bodyRegion == region.rawValue }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if moles.isEmpty {
                    emptyStateView
                } else {
                    moleListView
                }
            }
            .navigationTitle(String(localized: "title_mole_list"))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        NavigationLink(destination: AllRegionsOverviewView()) {
                            Label(String(localized: "all_regions_overview_menu"), systemImage: "square.grid.2x2")
                        }
                        
                        if !moles.isEmpty {
                            Divider()
                            
                            Button(action: { showingGuidedScanning = true }) {
                                Label(String(localized: "guided_scanning_title"), systemImage: "camera.metering.center.weighted")
                            }
                            
                            Button(action: { showingGuidedComparison = true }) {
                                Label(String(localized: "guided_comparison_title"), systemImage: "arrow.left.and.right.square")
                            }
                            
                            Divider()
                            
                            Button(action: { exportAllMoles() }) {
                                Label(String(localized: "action_export_all"), systemImage: "square.and.arrow.up")
                            }
                            
                            Button(action: { showingCleanup = true }) {
                                Label(String(localized: "cleanup_menu_item"), systemImage: "trash")
                            }
                        }
                    } label: {
                        Label(String(localized: "menu_label"), systemImage: "ellipsis.circle")
                    }
                    .disabled(isExporting)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddMole = true }) {
                        Label(String(localized: "action_add"), systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddMole) {
                AddMoleView(onMoleCreated: { mole in
                    newlyCreatedMole = mole
                })
            }
            .navigationDestination(item: $newlyCreatedMole) { mole in
                MoleDetailView(mole: mole)
            }
            .sheet(item: $exportURL) { url in
                ShareSheet(items: [url])
            }
            .sheet(isPresented: $showingCleanup) {
                SessionCleanupView()
            }
            .sheet(isPresented: $showingGuidedScanning) {
                GuidedScanningView(moles: moles)
            }
            .sheet(isPresented: $showingGuidedComparison) {
                GuidedComparisonView(moles: moles)
            }
            .overlay {
                if isExporting {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text(String(localized: "exporting_data"))
                                .font(.headline)
                        }
                        .padding(32)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text(String(localized: "empty_moles_title"))
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(String(localized: "empty_moles_message"))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: { showingAddMole = true }) {
                Label(String(localized: "empty_moles_button"), systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
        }
        .padding()
    }
    
    private var moleListView: some View {
        List {
            ForEach(groupedMoles, id: \.region) { group in
                Section {
                    // Overview images horizontal scroll
                    let regionOverviews = overviews(for: group.region)
                    if !regionOverviews.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(String(localized: "overview_images"))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                NavigationLink(destination: RegionOverviewView(region: group.region)) {
                                    Text(String(localized: "action_show_all"))
                                        .font(.caption)
                                }
                            }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(regionOverviews.prefix(5)) { overview in
                                        Button(action: {
                                            selectedOverview = overview
                                        }) {
                                            if let thumbnail = overview.thumbnailImage {
                                                Image(uiImage: thumbnail)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 100, height: 100)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                                    )
                                            }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding(.vertical, 4)
                    } else {
                        // Show button if no overviews exist
                        NavigationLink(destination: RegionOverviewView(region: group.region)) {
                            HStack {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .foregroundColor(.accentColor)
                                Text(String(localized: "overlay_add_overview"))
                                    .foregroundColor(.accentColor)
                                Spacer()
                            }
                        }
                    }
                    
                    // Individual moles
                    ForEach(group.moles) { mole in
                        NavigationLink(destination: MoleDetailView(mole: mole)) {
                            MoleRowView(mole: mole)
                        }
                    }
                    .onDelete { offsets in
                        confirmDeleteMoles(offsets: offsets, from: group.moles)
                    }
                } header: {
                    Text(group.region.localizedName)
                }
            }
        }
        .sheet(item: $selectedOverview) { overview in
            NavigationStack {
                OverviewImageDetailView(overview: overview)
            }
        }
        .alert(
            String(localized: "action_delete"),
            isPresented: $showingDeleteConfirmation,
            presenting: moleToDelete
        ) { mole in
            Button(String(localized: "action_cancel"), role: .cancel) {
                moleToDelete = nil
            }
            Button(String(localized: "action_delete"), role: .destructive) {
                if let mole = moleToDelete {
                    modelContext.delete(mole)
                    moleToDelete = nil
                }
            }
        } message: { mole in
            Text(String(localized: "delete_confirmation_mole", defaultValue: "Do you really want to delete this mole with all \(mole.imageCount) images? This action cannot be undone."))
        }
    }
    
    private func confirmDeleteMoles(offsets: IndexSet, from moles: [Mole]) {
        // For swipe to delete, we only handle single item deletion
        if let index = offsets.first {
            moleToDelete = moles[index]
            showingDeleteConfirmation = true
        }
    }
    
    private func exportAllMoles() {
        isExporting = true
        
        Task.detached(priority: .userInitiated) {
            if let url = ExportService.exportAllMoles(moles) {
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

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - URL Identifiable Extension
extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

// MARK: - Mole Row View
struct MoleRowView: View {
    let mole: Mole
    
    // Get localized region name
    private var localizedRegion: String {
        if let region = BodyRegion.allCases.first(where: { $0.legacyRawValue == mole.bodyRegion || $0.rawValue == mole.bodyRegion }) {
            return region.localizedName
        }
        return mole.bodyRegion
    }
    
    // Get localized side name
    private var localizedSide: String {
        if let region = BodyRegion.allCases.first(where: { $0.legacyRawValue == mole.bodyRegion || $0.rawValue == mole.bodyRegion }),
           let side = BodySide.availableSides(for: region).first(where: { $0.legacyRawValue == mole.bodySide || $0.rawValue == mole.bodySide }) {
            return side.displayText
        }
        return mole.bodySide
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let firstImage = mole.latestImage,
               let thumbnail = firstImage.thumbnailImage {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    }
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text("\(localizedRegion) - \(localizedSide)")
                    .font(.headline)
                
                HStack(spacing: 12) {
                    Label("\(mole.imageCount)", systemImage: "photo.stack")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let latestImage = mole.latestImage {
                        Label(latestImage.captureDate.formatted(date: .abbreviated, time: .omitted), 
                              systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Mole View
struct AddMoleView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let onMoleCreated: ((Mole) -> Void)?
    
    @State private var selectedRegion = BodyRegion.head
    @State private var selectedSide = BodySide.headFront
    @State private var showingCamera = false
    @State private var capturedImage: UIImage?
    
    init(onMoleCreated: ((Mole) -> Void)? = nil) {
        self.onMoleCreated = onMoleCreated
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "label_body_region")) {
                    Picker(String(localized: "label_region"), selection: $selectedRegion) {
                        ForEach(BodyRegion.allCases) { region in
                            Text(region.localizedName).tag(region)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedRegion) { _, newValue in
                        // Update available sides for new region
                        let availableSides = BodySide.availableSides(for: newValue)
                        
                        // If current side is not available for new region, use default
                        if !availableSides.contains(selectedSide) {
                            selectedSide = BodySide.defaultSide(for: newValue)
                        }
                    }
                    
                    Picker(String(localized: "label_side"), selection: $selectedSide) {
                        ForEach(BodySide.availableSides(for: selectedRegion)) { side in
                            Text(side.displayText).tag(side)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section(String(localized: "label_photo")) {
                    if let image = capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                        
                        Button(String(localized: "action_take_new_photo")) {
                            showingCamera = true
                        }
                    } else {
                        Button(action: { showingCamera = true }) {
                            Label(String(localized: "action_take_photo"), systemImage: "camera.fill")
                        }
                    }
                }
            }
            .navigationTitle(String(localized: "title_add_mole"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "action_cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "action_save")) {
                        saveMole()
                    }
                    .disabled(capturedImage == nil)
                }
            }
            .sheet(isPresented: $showingCamera) {
                CameraView { image in
                    capturedImage = image
                }
            }
        }
    }
    
    private func saveMole() {
        let newMole = Mole(bodyRegion: selectedRegion.rawValue, bodySide: selectedSide.rawValue)
        
        if let image = capturedImage,
           let moleImage = MoleImage(image: image) {
            newMole.images.append(moleImage)
            moleImage.mole = newMole
        }
        
        modelContext.insert(newMole)
        dismiss()
        
        // Notify parent that mole was created
        onMoleCreated?(newMole)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Mole.self, MoleImage.self], inMemory: true)
}