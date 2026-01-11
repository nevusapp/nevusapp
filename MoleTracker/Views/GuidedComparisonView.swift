//
//  GuidedComparisonView.swift
//  MoleTracker
//
//  Created on 11.01.2026.
//

import SwiftUI
import SwiftData

struct GuidedComparisonView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var comparisonService = GuidedComparisonService()
    
    let moles: [Mole]
    
    @State private var showingCancelConfirmation = false
    @State private var showingCompletionSheet = false
    @State private var editedNotes: String = ""
    @State private var isEditingNotes = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress Header
                progressHeader
                
                Divider()
                
                // Current Mole Content
                if let currentMole = comparisonService.currentMole {
                    currentMoleView(currentMole)
                } else {
                    completionView
                }
            }
            .navigationTitle(String(localized: "guided_comparison_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "action_cancel")) {
                        showingCancelConfirmation = true
                    }
                }
            }
            .alert(String(localized: "comparison_cancel_title"), isPresented: $showingCancelConfirmation) {
                Button(String(localized: "action_continue"), role: .cancel) { }
                Button(String(localized: "action_cancel"), role: .destructive) {
                    comparisonService.cancelComparison()
                    dismiss()
                }
            } message: {
                Text(String(localized: "comparison_cancel_message"))
            }
            .sheet(isPresented: $showingCompletionSheet) {
                completionSummarySheet
            }
            .onAppear {
                comparisonService.startComparison(moles: moles)
            }
        }
    }
    
    // MARK: - Progress Header
    private var progressHeader: some View {
        VStack(spacing: 12) {
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.accentColor)
                        .frame(width: geometry.size.width * comparisonService.progress, height: 12)
                        .animation(.easeInOut, value: comparisonService.progress)
                }
            }
            .frame(height: 12)
            
            // Progress Text
            HStack {
                Text("\(comparisonService.comparedCount) von \(comparisonService.totalMoles) verglichen")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(comparisonService.progress * 100))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.accentColor)
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Current Mole View
    private func currentMoleView(_ mole: Mole) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Mole Info Card
                VStack(spacing: 16) {
                    // Position indicator
                    Text("Leberfleck \(comparisonService.currentMoleIndex + 1) von \(comparisonService.totalMoles)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Mole details
                    VStack(spacing: 8) {
                        Text(localizedRegion(for: mole))
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(localizedSide(for: mole))
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Image count
                    Label("\(mole.imageCount) Fotos", systemImage: "photo.stack")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(radius: 2)
                
                // Comparison View - Full Width
                if let referenceImage = mole.referenceImage,
                   let latestImage = mole.latestImage,
                   referenceImage.id != latestImage.id {
                    VStack(spacing: 0) {
                        // Header
                        Text(String(localized: "title_image_comparison"))
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top, 12)
                            .padding(.bottom, 8)
                            .background(Color(.systemBackground))
                        
                        // Full-width comparison view
                        ComparisonView(image1: referenceImage, image2: latestImage)
                            .frame(height: 500)
                    }
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 2)
                } else {
                    // Not enough images for comparison
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        
                        Text(String(localized: "not_enough_images"))
                            .font(.headline)
                        
                        Text(String(localized: "minimum_images_required"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 2)
                }
                
                // Notes Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label(String(localized: "label_notes"), systemImage: "note.text")
                            .font(.headline)
                        
                        Spacer()
                        
                        if !isEditingNotes {
                            Button(action: {
                                editedNotes = mole.notes
                                isEditingNotes = true
                            }) {
                                Text(String(localized: "action_edit"))
                                    .font(.subheadline)
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    
                    if isEditingNotes {
                        VStack(spacing: 12) {
                            TextEditor(text: $editedNotes)
                                .frame(minHeight: 100)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            HStack {
                                Button(action: {
                                    isEditingNotes = false
                                    editedNotes = ""
                                }) {
                                    Text(String(localized: "action_cancel"))
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .foregroundColor(.primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                
                                Button(action: {
                                    mole.notes = editedNotes
                                    mole.updateModifiedDate()
                                    isEditingNotes = false
                                }) {
                                    Text(String(localized: "action_save"))
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.accentColor)
                                        .foregroundColor(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    } else {
                        if mole.notes.isEmpty {
                            Text(String(localized: "no_notes_available"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            Text(mole.notes)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(radius: 2)
                
                // Action Buttons
                VStack(spacing: 12) {
                    // Mark as Compared Button
                    Button(action: {
                        if isEditingNotes {
                            mole.notes = editedNotes
                            mole.updateModifiedDate()
                            isEditingNotes = false
                        }
                        comparisonService.markCurrentAsCompared()
                    }) {
                        Label(String(localized: "action_compared"), systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Skip Button
                    Button(action: {
                        if isEditingNotes {
                            isEditingNotes = false
                            editedNotes = ""
                        }
                        comparisonService.skipCurrent()
                    }) {
                        Label(String(localized: "action_skip"), systemImage: "forward.fill")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Back Button (if not first)
                    if comparisonService.currentMoleIndex > 0 {
                        Button(action: {
                            if isEditingNotes {
                                isEditingNotes = false
                                editedNotes = ""
                            }
                            comparisonService.goToPrevious()
                        }) {
                            Label(String(localized: "action_back"), systemImage: "arrow.left")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .foregroundColor(.secondary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                
                // Overview Images - NEW SECTION
                if !mole.locationMarkers.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(localized: "linked_overview_images"))
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(mole.locationMarkers) { marker in
                                    if let overview = marker.overviewImage,
                                       let thumbnail = overview.thumbnailImage {
                                        VStack(spacing: 4) {
                                            ZStack(alignment: .center) {
                                                Image(uiImage: thumbnail)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 120, height: 120)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                                
                                                // Marker position indicator
                                                Circle()
                                                    .fill(Color.red)
                                                    .frame(width: 16, height: 16)
                                                    .overlay(
                                                        Circle()
                                                            .stroke(Color.white, lineWidth: 2)
                                                    )
                                                    .offset(
                                                        x: (marker.normalizedX - 0.5) * 120,
                                                        y: (marker.normalizedY - 0.5) * 120
                                                    )
                                            }
                                            
                                            Text(overview.captureDate.formatted(date: .abbreviated, time: .omitted))
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }
                                        .frame(width: 120)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 2)
                }
                
                // Instructions
                VStack(alignment: .leading, spacing: 12) {
                    Label(String(localized: "instructions_title"), systemImage: "info.circle.fill")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        instructionRow(number: 1, text: String(localized: "instruction_compare_images"))
                        instructionRow(number: 2, text: String(localized: "instruction_use_comparison_modes"))
                        instructionRow(number: 3, text: String(localized: "instruction_update_notes"))
                        instructionRow(number: 4, text: String(localized: "instruction_mark_or_skip"))
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(radius: 2)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Completion View
    private var completionView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text(String(localized: "comparison_complete"))
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                Text(String(localized: "moles_compared_count", defaultValue: "\(comparisonService.comparedCount) Moles Compared"))
                    .font(.headline)
                
                if comparisonService.skippedMoles.count > 0 {
                    Text(String(localized: "count_skipped", defaultValue: "\(comparisonService.skippedMoles.count) Skipped"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Button(action: {
                showingCompletionSheet = true
            }) {
                Text(String(localized: "action_show_summary"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            
            Button(action: {
                dismiss()
            }) {
                Text(String(localized: "action_done"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Completion Summary Sheet
    private var completionSummarySheet: some View {
        NavigationStack {
            List {
                Section(String(localized: "section_statistics")) {
                    LabeledContent(String(localized: "action_compared"), value: "\(comparisonService.comparedCount)")
                    LabeledContent(String(localized: "label_skipped"), value: "\(comparisonService.skippedMoles.count)")
                    LabeledContent(String(localized: "label_total"), value: "\(comparisonService.totalMoles)")
                }
                
                if comparisonService.comparedCount > 0 {
                    Section(String(localized: "section_compared_moles")) {
                        ForEach(moles.filter { comparisonService.comparedMoles.contains($0.id) }) { mole in
                            HStack {
                                if let thumbnail = mole.latestImage?.thumbnailImage {
                                    Image(uiImage: thumbnail)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 50, height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(localizedRegion(for: mole))
                                        .font(.headline)
                                    Text(localizedSide(for: mole))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                
                if comparisonService.skippedMoles.count > 0 {
                    Section(String(localized: "section_skipped_moles")) {
                        ForEach(moles.filter { comparisonService.skippedMoles.contains($0.id) }) { mole in
                            HStack {
                                if let thumbnail = mole.latestImage?.thumbnailImage {
                                    Image(uiImage: thumbnail)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 50, height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(localizedRegion(for: mole))
                                        .font(.headline)
                                    Text(localizedSide(for: mole))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(String(localized: "title_summary"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "action_done")) {
                        showingCompletionSheet = false
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Views
    private func instructionRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 28, height: 28)
                
                Text("\(number)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.accentColor)
            }
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
    
    // MARK: - Helper Functions
    private func localizedRegion(for mole: Mole) -> String {
        if let region = BodyRegion.allCases.first(where: { $0.legacyRawValue == mole.bodyRegion || $0.rawValue == mole.bodyRegion }) {
            return region.localizedName
        }
        return mole.bodyRegion
    }
    
    private func localizedSide(for mole: Mole) -> String {
        if let region = BodyRegion.allCases.first(where: { $0.legacyRawValue == mole.bodyRegion || $0.rawValue == mole.bodyRegion }),
           let side = BodySide.availableSides(for: region).first(where: { $0.legacyRawValue == mole.bodySide || $0.rawValue == mole.bodySide }) {
            return side.displayText
        }
        return mole.bodySide
    }
}

#Preview {
    GuidedComparisonView(moles: [
        Mole(bodyRegion: "Kopf", bodySide: "Links"),
        Mole(bodyRegion: "Arm/Hand rechts", bodySide: "Oberarm-Vorne (Bizeps)")
    ])
    .modelContainer(for: [Mole.self, MoleImage.self], inMemory: true)
}
