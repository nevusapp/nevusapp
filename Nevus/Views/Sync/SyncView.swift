//
//  SyncView.swift
//  Nevus
//
//  Created on 28.02.2026.
//

import SwiftUI
import SwiftData

struct SyncView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var moles: [Mole]
    @Query private var overviews: [BodyRegionOverview]
    
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var isExporting = false
    @State private var exportURL: URL?
    @State private var showingShareSheet = false
    @State private var showingConfirmation = false
    @State private var exportStats: ExportStats?
    @State private var errorMessage: String?
    @State private var showingError = false
    
    struct ExportStats {
        let moleCount: Int
        let imageCount: Int
        let sinceDate: Date
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        String(localized: "sync_date_picker_label", defaultValue: "Export data since"),
                        selection: $selectedDate,
                        in: ...Date(),
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                } header: {
                    Text(String(localized: "sync_date_section_header", defaultValue: "Select Date"))
                } footer: {
                    Text(String(localized: "sync_date_section_footer", defaultValue: "Only moles and images created or modified since this date will be exported."))
                }
                
                Section {
                    Button(action: { showExportPreview() }) {
                        HStack {
                            Image(systemName: "arrow.up.doc")
                            Text(String(localized: "sync_preview_button", defaultValue: "Preview Export"))
                            Spacer()
                            if isExporting {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isExporting)
                } header: {
                    Text(String(localized: "sync_export_section_header", defaultValue: "Export"))
                } footer: {
                    Text(String(localized: "sync_export_section_footer", defaultValue: "Preview what will be exported before sharing."))
                }
                
                if let stats = exportStats {
                    Section {
                        HStack {
                            Text(String(localized: "sync_stats_moles", defaultValue: "Moles"))
                            Spacer()
                            Text("\(stats.moleCount)")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text(String(localized: "sync_stats_images", defaultValue: "Images"))
                            Spacer()
                            Text("\(stats.imageCount)")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text(String(localized: "sync_stats_since", defaultValue: "Since"))
                            Spacer()
                            Text(stats.sinceDate.formatted(date: .abbreviated, time: .omitted))
                                .foregroundColor(.secondary)
                        }
                        
                        Button(action: { performExport() }) {
                            HStack {
                                Spacer()
                                Image(systemName: "square.and.arrow.up")
                                Text(String(localized: "sync_share_button", defaultValue: "Share via AirDrop"))
                                Spacer()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isExporting)
                    } header: {
                        Text(String(localized: "sync_preview_section_header", defaultValue: "Export Preview"))
                    }
                }
            }
            .navigationTitle(String(localized: "sync_title", defaultValue: "Sync Data"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "action_cancel")) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
            .alert(
                String(localized: "sync_confirm_title", defaultValue: "Export Data?"),
                isPresented: $showingConfirmation,
                presenting: exportStats
            ) { stats in
                Button(String(localized: "action_cancel"), role: .cancel) {
                    exportStats = nil
                }
                Button(String(localized: "sync_confirm_button", defaultValue: "Export")) {
                    performExport()
                }
            } message: { stats in
                Text(String(localized: "sync_confirm_message", defaultValue: "Export \(stats.moleCount) mole(s) with \(stats.imageCount) image(s) created since \(stats.sinceDate.formatted(date: .abbreviated, time: .omitted))?"))
            }
            .alert(
                String(localized: "error_title", defaultValue: "Error"),
                isPresented: $showingError,
                presenting: errorMessage
            ) { _ in
                Button(String(localized: "action_ok", defaultValue: "OK"), role: .cancel) {
                    errorMessage = nil
                }
            } message: { message in
                Text(message)
            }
            .overlay {
                if isExporting {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text(String(localized: "sync_exporting", defaultValue: "Preparing export..."))
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
    
    private func showExportPreview() {
        isExporting = true
        
        Task {
            // Calculate what would be exported
            let stats = await calculateExportStats()
            
            await MainActor.run {
                isExporting = false
                
                if stats.imageCount == 0 {
                    errorMessage = String(localized: "sync_no_data_error", defaultValue: "No new data to export since the selected date.")
                    showingError = true
                } else {
                    exportStats = stats
                }
            }
        }
    }
    
    private func calculateExportStats() async -> ExportStats {
        var moleCount = 0
        var imageCount = 0
        var processedMoleIDs = Set<UUID>()
        
        for mole in moles {
            let newImages = mole.images.filter { $0.captureDate >= selectedDate }
            
            if !newImages.isEmpty {
                if !processedMoleIDs.contains(mole.id) {
                    moleCount += 1
                    processedMoleIDs.insert(mole.id)
                }
                imageCount += newImages.count
            }
        }
        
        return ExportStats(
            moleCount: moleCount,
            imageCount: imageCount,
            sinceDate: selectedDate
        )
    }
    
    private func performExport() {
        isExporting = true
        
        Task(priority: .userInitiated) {
            if let url = ExportService.exportDeltaSync(moles: moles, overviews: overviews, sinceDate: selectedDate) {
                await MainActor.run {
                    exportURL = url
                    isExporting = false
                    showingShareSheet = true
                }
            } else {
                await MainActor.run {
                    isExporting = false
                    errorMessage = String(localized: "sync_export_failed", defaultValue: "Failed to create export package. Please try again.")
                    showingError = true
                }
            }
        }
    }
}

#Preview {
    SyncView()
        .modelContainer(for: [Mole.self, MoleImage.self], inMemory: true)
}