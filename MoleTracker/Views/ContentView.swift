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
    @State private var showingAddMole = false
    @State private var showingCamera = false
    @State private var selectedMole: Mole?
    @State private var showingExportSheet = false
    @State private var exportURL: URL?
    @State private var isExporting = false
    
    // Group moles by body region
    var groupedMoles: [(region: BodyRegion, moles: [Mole])] {
        let grouped = Dictionary(grouping: moles) { mole -> BodyRegion in
            BodyRegion.allCases.first { $0.rawValue == mole.bodyRegion } ?? .head
        }
        
        return BodyRegion.displayOrder.compactMap { region in
            guard let molesInRegion = grouped[region], !molesInRegion.isEmpty else { return nil }
            let sortedMoles = molesInRegion.sorted { $0.lastModified > $1.lastModified }
            return (region: region, moles: sortedMoles)
        }
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
            .navigationTitle("Meine Leberflecke")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !moles.isEmpty {
                        Menu {
                            Button(action: { exportAllMoles() }) {
                                Label("Alle exportieren", systemImage: "square.and.arrow.up")
                            }
                        } label: {
                            Label("Export", systemImage: "square.and.arrow.up")
                        }
                        .disabled(isExporting)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddMole = true }) {
                        Label("Hinzufügen", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddMole) {
                AddMoleView()
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
                            Text("Exportiere Daten...")
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
            
            Text("Keine Leberflecke erfasst")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Tippen Sie auf +, um Ihren ersten Leberfleck zu erfassen")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: { showingAddMole = true }) {
                Label("Ersten Leberfleck hinzufügen", systemImage: "plus.circle.fill")
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
                Section(header: Text(group.region.rawValue)) {
                    ForEach(group.moles) { mole in
                        NavigationLink(destination: MoleDetailView(mole: mole)) {
                            MoleRowView(mole: mole)
                        }
                    }
                    .onDelete { offsets in
                        deleteMoles(offsets: offsets, from: group.moles)
                    }
                }
            }
        }
    }
    
    private func deleteMoles(offsets: IndexSet, from moles: [Mole]) {
        for index in offsets {
            modelContext.delete(moles[index])
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
                Text("\(mole.bodyRegion) - \(mole.bodySide)")
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
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Mole View
struct AddMoleView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedRegion = BodyRegion.head
    @State private var selectedSide = BodySide.center
    @State private var showingCamera = false
    @State private var capturedImage: UIImage?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Körperregion") {
                    Picker("Region", selection: $selectedRegion) {
                        ForEach(BodyRegion.allCases) { region in
                            Text(region.rawValue).tag(region)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Picker("Seite", selection: $selectedSide) {
                        ForEach(BodySide.allCases) { side in
                            Text(side.rawValue).tag(side)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Foto") {
                    if let image = capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                        
                        Button("Neues Foto aufnehmen") {
                            showingCamera = true
                        }
                    } else {
                        Button(action: { showingCamera = true }) {
                            Label("Foto aufnehmen", systemImage: "camera.fill")
                        }
                    }
                }
            }
            .navigationTitle("Neuer Leberfleck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Speichern") {
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
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Mole.self, MoleImage.self], inMemory: true)
}