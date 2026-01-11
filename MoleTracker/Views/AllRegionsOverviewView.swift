//
//  AllRegionsOverviewView.swift
//  MoleTracker
//
//  Created on 11.01.2026.
//

import SwiftUI
import SwiftData

struct AllRegionsOverviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BodyRegionOverview.captureDate, order: .reverse)
    private var allOverviews: [BodyRegionOverview]
    @State private var selectedRegion: BodyRegion?
    @State private var selectedOverview: BodyRegionOverview?
    
    // Group overviews by body region
    private func overviews(for region: BodyRegion) -> [BodyRegionOverview] {
        allOverviews.filter { $0.bodyRegion == region.legacyRawValue || $0.bodyRegion == region.rawValue }
    }
    
    var body: some View {
        List {
            ForEach(BodyRegion.displayOrder, id: \.self) { region in
                Section {
                    let regionOverviews = overviews(for: region)
                    
                    if regionOverviews.isEmpty {
                        // Empty state for this region
                        NavigationLink(destination: RegionOverviewView(region: region)) {
                            HStack {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .foregroundColor(.secondary)
                                    .frame(width: 30)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(String(localized: "no_overview_images"))
                                        .foregroundColor(.secondary)
                                    Text(String(localized: "tap_to_add_overview"))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                            .padding(.vertical, 8)
                        }
                    } else {
                        // Show overview images in a grid
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(String(localized: "overview_count", defaultValue: "\(regionOverviews.count) images", comment: "Count of overview images"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                NavigationLink(destination: RegionOverviewView(region: region)) {
                                    HStack(spacing: 4) {
                                        Text(String(localized: "action_manage"))
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                    }
                                    .font(.caption)
                                }
                            }
                            
                            // Grid of overview images
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 8),
                                GridItem(.flexible(), spacing: 8),
                                GridItem(.flexible(), spacing: 8)
                            ], spacing: 8) {
                                ForEach(regionOverviews.prefix(6)) { overview in
                                    Button(action: {
                                        selectedOverview = overview
                                    }) {
                                        if let thumbnail = overview.thumbnailImage {
                                            Image(uiImage: thumbnail)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(height: 100)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                                )
                                        } else {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.gray.opacity(0.1))
                                                .frame(height: 100)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                // Show "more" indicator if there are more than 6 images
                                if regionOverviews.count > 6 {
                                    NavigationLink(destination: RegionOverviewView(region: region)) {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.gray.opacity(0.1))
                                            .frame(height: 100)
                                            .overlay {
                                                VStack(spacing: 4) {
                                                    Text("+\(regionOverviews.count - 6)")
                                                        .font(.title2)
                                                        .fontWeight(.semibold)
                                                    Text(String(localized: "more_images"))
                                                        .font(.caption2)
                                                }
                                                .foregroundColor(.secondary)
                                            }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text(region.localizedName)
                }
            }
        }
        .navigationTitle(String(localized: "all_regions_overview_title"))
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedOverview) { overview in
            NavigationStack {
                OverviewImageDetailView(overview: overview)
            }
        }
    }
}

#Preview {
    NavigationStack {
        AllRegionsOverviewView()
            .modelContainer(for: [BodyRegionOverview.self], inMemory: true)
    }
}