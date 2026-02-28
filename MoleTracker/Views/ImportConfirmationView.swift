//
//  ImportConfirmationView.swift
//  MoleTracker
//
//  Created on 28.02.2026.
//

import SwiftUI
import SwiftData

struct ImportConfirmationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let fileURL: URL
    
    @State private var isLoading = true
    @State private var isImporting = false
    @State private var packageInfo: PackageInfo?
    @State private var importResult: ImportService.ImportResult?
    @State private var errorMessage: String?
    @State private var showingError = false
    
    struct PackageInfo {
        let exportDate: Date
        let sinceDate: Date
        let moleCount: Int
        let imageCount: Int
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else if let result = importResult {
                    resultView(result: result)
                } else if let info = packageInfo {
                    confirmationView(info: info)
                } else {
                    errorView
                }
            }
            .navigationTitle(String(localized: "import_title", defaultValue: "Import Data"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "action_cancel")) {
                        dismiss()
                    }
                    .disabled(isImporting)
                }
            }
            .alert(
                String(localized: "error_title", defaultValue: "Error"),
                isPresented: $showingError,
                presenting: errorMessage
            ) { _ in
                Button(String(localized: "action_ok", defaultValue: "OK"), role: .cancel) {
                    errorMessage = nil
                    dismiss()
                }
            } message: { message in
                Text(message)
            }
            .task {
                await loadPackageInfo()
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text(String(localized: "import_loading", defaultValue: "Reading package..."))
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func confirmationView(info: PackageInfo) -> some View {
        Form {
            Section {
                HStack {
                    Text(String(localized: "import_info_moles", defaultValue: "Moles"))
                    Spacer()
                    Text("\(info.moleCount)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text(String(localized: "import_info_images", defaultValue: "Images"))
                    Spacer()
                    Text("\(info.imageCount)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text(String(localized: "import_info_since", defaultValue: "Since"))
                    Spacer()
                    Text(info.sinceDate.formatted(date: .abbreviated, time: .omitted))
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text(String(localized: "import_info_exported", defaultValue: "Exported"))
                    Spacer()
                    Text(info.exportDate.formatted(date: .abbreviated, time: .shortened))
                        .foregroundColor(.secondary)
                }
            } header: {
                Text(String(localized: "import_package_info_header", defaultValue: "Package Information"))
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Label {
                        Text(String(localized: "import_info_duplicates", defaultValue: "Duplicate items will be skipped"))
                    } icon: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    
                    Label {
                        Text(String(localized: "import_info_merge", defaultValue: "New data will be merged with existing"))
                    } icon: {
                        Image(systemName: "arrow.triangle.merge")
                            .foregroundColor(.blue)
                    }
                    
                    Label {
                        Text(String(localized: "import_info_safe", defaultValue: "Your existing data will not be deleted"))
                    } icon: {
                        Image(systemName: "shield.fill")
                            .foregroundColor(.orange)
                    }
                }
                .font(.subheadline)
            } header: {
                Text(String(localized: "import_behavior_header", defaultValue: "Import Behavior"))
            }
            
            Section {
                Button(action: { performImport() }) {
                    HStack {
                        Spacer()
                        if isImporting {
                            ProgressView()
                                .padding(.trailing, 8)
                        }
                        Text(String(localized: "import_confirm_button", defaultValue: "Import Data"))
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isImporting)
            }
        }
    }
    
    private func resultView(result: ImportService.ImportResult) -> some View {
        Form {
            Section {
                if result.hasNewData {
                    Label {
                        Text(String(localized: "import_success", defaultValue: "Import completed successfully"))
                    } icon: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    .font(.headline)
                } else {
                    Label {
                        Text(String(localized: "import_no_new_data", defaultValue: "No new data to import"))
                    } icon: {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                    }
                    .font(.headline)
                }
            }
            
            Section {
                if result.molesImported > 0 {
                    HStack {
                        Text(String(localized: "import_result_moles_imported", defaultValue: "Moles imported"))
                        Spacer()
                        Text("\(result.molesImported)")
                            .foregroundColor(.green)
                            .fontWeight(.semibold)
                    }
                }
                
                if result.imagesImported > 0 {
                    HStack {
                        Text(String(localized: "import_result_images_imported", defaultValue: "Images imported"))
                        Spacer()
                        Text("\(result.imagesImported)")
                            .foregroundColor(.green)
                            .fontWeight(.semibold)
                    }
                }
                
                if result.molesSkipped > 0 {
                    HStack {
                        Text(String(localized: "import_result_moles_skipped", defaultValue: "Moles skipped"))
                        Spacer()
                        Text("\(result.molesSkipped)")
                            .foregroundColor(.secondary)
                    }
                }
                
                if result.imagesSkipped > 0 {
                    HStack {
                        Text(String(localized: "import_result_images_skipped", defaultValue: "Images skipped"))
                        Spacer()
                        Text("\(result.imagesSkipped)")
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text(String(localized: "import_result_header", defaultValue: "Import Results"))
            }
            
            if !result.errors.isEmpty {
                Section {
                    ForEach(result.errors, id: \.self) { error in
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                } header: {
                    Text(String(localized: "import_errors_header", defaultValue: "Errors"))
                }
            }
            
            Section {
                Button(action: { dismiss() }) {
                    HStack {
                        Spacer()
                        Text(String(localized: "action_done", defaultValue: "Done"))
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text(String(localized: "import_error_title", defaultValue: "Cannot Read Package"))
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(String(localized: "import_error_message", defaultValue: "The sync package could not be read. It may be corrupted or from an incompatible version."))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: { dismiss() }) {
                Text(String(localized: "action_close", defaultValue: "Close"))
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
    
    private func loadPackageInfo() async {
        do {
            // Read package manifest to show preview
            let fileManager = FileManager.default
            let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
            
            defer {
                try? fileManager.removeItem(at: tempDir)
            }
            
            // Unzip to read manifest
            var coordinatorError: NSError?
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                NSFileCoordinator().coordinate(readingItemAt: fileURL, options: [.forUploading], error: &coordinatorError) { zipURL in
                    do {
                        let contents = try fileManager.contentsOfDirectory(at: zipURL, includingPropertiesForKeys: nil)
                        for item in contents {
                            let destItem = tempDir.appendingPathComponent(item.lastPathComponent)
                            try fileManager.copyItem(at: item, to: destItem)
                        }
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
                
                if let error = coordinatorError {
                    continuation.resume(throwing: error)
                }
            }
            
            // Read manifest
            let manifestURL = tempDir.appendingPathComponent("manifest.json")
            let manifestData = try Data(contentsOf: manifestURL)
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let syncPackage = try decoder.decode(SyncPackage.self, from: manifestData)
            
            await MainActor.run {
                packageInfo = PackageInfo(
                    exportDate: syncPackage.exportDate,
                    sinceDate: syncPackage.sinceDate,
                    moleCount: syncPackage.moles.count,
                    imageCount: syncPackage.images.count
                )
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingError = true
                isLoading = false
            }
        }
    }
    
    private func performImport() {
        isImporting = true
        
        Task {
            do {
                let result = try await ImportService.importSyncPackage(from: fileURL, modelContext: modelContext)
                
                await MainActor.run {
                    importResult = result
                    isImporting = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isImporting = false
                }
            }
        }
    }
}

#Preview {
    ImportConfirmationView(fileURL: URL(fileURLWithPath: "/tmp/test.moletracker"))
        .modelContainer(for: [Mole.self, MoleImage.self], inMemory: true)
}
