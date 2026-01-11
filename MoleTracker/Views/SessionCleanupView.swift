import SwiftUI
import SwiftData

struct SessionCleanupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var moles: [Mole]
    @Query(sort: \BodyRegionOverview.captureDate, order: .reverse)
    private var overviews: [BodyRegionOverview]
    
    @State private var sessions: [CleanupService.RecordingSession] = []
    @State private var selectedSessions: Set<CleanupService.RecordingSession> = []
    @State private var showingDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var deletionResult: (deletedCount: Int, freedSpace: Int64)?
    @State private var showingResult = false
    
    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    emptyStateView
                } else {
                    sessionListView
                }
            }
            .navigationTitle(String(localized: "cleanup_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "action_cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "cleanup_delete_button")) {
                        showingDeleteConfirmation = true
                    }
                    .disabled(selectedSessions.isEmpty || isDeleting)
                }
            }
            .onAppear {
                loadSessions()
            }
            .alert(String(localized: "cleanup_confirm_title"), isPresented: $showingDeleteConfirmation) {
                Button(String(localized: "action_cancel"), role: .cancel) { }
                Button(String(localized: "cleanup_confirm_delete"), role: .destructive) {
                    performCleanup()
                }
            } message: {
                Text(String(localized: "cleanup_confirm_message_\(selectedSessions.count)_\(totalDeletablePhotos)"))
            }
            .alert(String(localized: "cleanup_result_title"), isPresented: $showingResult) {
                Button(String(localized: "action_ok")) {
                    dismiss()
                }
            } message: {
                if let result = deletionResult {
                    Text(String(localized: "cleanup_result_message_\(result.deletedCount)_\(CleanupService.formatBytes(result.freedSpace))"))
                }
            }
            .overlay {
                if isDeleting {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text(String(localized: "cleanup_deleting"))
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
            Image(systemName: "photo.stack")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text(String(localized: "cleanup_empty_title"))
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(String(localized: "cleanup_empty_message"))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
    
    private var sessionListView: some View {
        List {
            Section {
                Text(String(localized: "cleanup_description"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Section {
                ForEach(sessions) { session in
                    SessionRowView(
                        session: session,
                        isSelected: selectedSessions.contains(session)
                    ) {
                        toggleSelection(session)
                    }
                }
            } header: {
                HStack {
                    Text(String(localized: "cleanup_sessions_header"))
                    Spacer()
                    if !selectedSessions.isEmpty {
                        Button(selectedSessions.count == sessions.count ? 
                               String(localized: "cleanup_deselect_all") : 
                               String(localized: "cleanup_select_all")) {
                            if selectedSessions.count == sessions.count {
                                selectedSessions.removeAll()
                            } else {
                                selectedSessions = Set(sessions)
                            }
                        }
                        .font(.caption)
                        .textCase(.none)
                    }
                }
            }
            
            if !selectedSessions.isEmpty {
                Section {
                    HStack {
                        Text(String(localized: "cleanup_selected_sessions"))
                        Spacer()
                        Text("\(selectedSessions.count)")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text(String(localized: "cleanup_photos_to_delete"))
                        Spacer()
                        Text("\(totalDeletablePhotos)")
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                } header: {
                    Text(String(localized: "cleanup_summary"))
                }
            }
        }
    }
    
    private var totalDeletablePhotos: Int {
        selectedSessions.reduce(0) { $0 + $1.deletablePhotoCount }
    }
    
    private func loadSessions() {
        sessions = CleanupService.getRecordingSessions(from: moles, overviews: overviews)
    }
    
    private func toggleSelection(_ session: CleanupService.RecordingSession) {
        if selectedSessions.contains(session) {
            selectedSessions.remove(session)
        } else {
            selectedSessions.insert(session)
        }
    }
    
    private func performCleanup() {
        isDeleting = true
        
        Task.detached(priority: .userInitiated) {
            // Create a mutable copy of moles array
            var mutableMoles = await MainActor.run { moles }
            
            // Perform deletion
            let result = CleanupService.deletePhotosFromSessions(
                selectedSessions,
                moles: &mutableMoles
            )
            
            // Update the model context on main actor
            await MainActor.run {
                // The changes are already reflected in the SwiftData context
                // since we're working with reference types
                try? modelContext.save()
                
                deletionResult = result
                isDeleting = false
                showingResult = true
            }
        }
    }
}

// MARK: - Session Row View
struct SessionRowView: View {
    let session: CleanupService.RecordingSession
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? .accentColor : .gray)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.dateString)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 16) {
                        Label("\(session.photoCount)", systemImage: "photo")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if session.deletablePhotoCount > 0 {
                            Label(String(localized: "cleanup_deletable_\(session.deletablePhotoCount)"), 
                                  systemImage: "trash")
                                .font(.caption)
                                .foregroundColor(.red)
                        } else {
                            Text(String(localized: "cleanup_no_deletable"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(session.deletablePhotoCount == 0)
        .opacity(session.deletablePhotoCount == 0 ? 0.5 : 1.0)
    }
}

#Preview {
    SessionCleanupView()
        .modelContainer(for: [Mole.self, MoleImage.self], inMemory: true)
}