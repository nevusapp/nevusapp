//
//  ComparisonView.swift
//  MoleTracker
//
//  Created on 06.01.2026.
//

import SwiftUI

struct ComparisonView: View {
    let image1: MoleImage
    let image2: MoleImage
    
    @State private var comparisonMode: ComparisonMode = .overlay
    @State private var sliderPosition: CGFloat = 0.5
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset: CGSize = .zero
    
    enum ComparisonMode: String, CaseIterable {
        case sideBySide = "Nebeneinander"
        case overlay = "Überlagert"
        
        var icon: String {
            switch self {
            case .sideBySide: return "rectangle.split.2x1"
            case .overlay: return "square.on.square"
            }
        }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Spacer for picker
                Color.clear
                    .frame(height: 60)
                
                // Comparison Area
                GeometryReader { geometry in
                    ZStack {
                        if comparisonMode == .sideBySide {
                            sideBySideView(geometry: geometry)
                        } else {
                            overlayView(geometry: geometry)
                        }
                    }
                }
                
                // Image Info
                imageInfoView
                    .padding()
                    .background(.ultraThinMaterial)
            }
            
            // Mode Picker - overlay on top
            VStack {
                Picker("Vergleichsmodus", selection: $comparisonMode) {
                    ForEach(ComparisonMode.allCases, id: \.self) { mode in
                        Label(mode.rawValue, systemImage: mode.icon)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .background(.ultraThinMaterial)
                
                Spacer()
            }
        }
        .navigationTitle("Bildvergleich")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: comparisonMode) { _, _ in
            // Reset zoom and offset when switching modes
            scale = 1.0
            lastScale = 1.0
            offset = .zero
            lastOffset = .zero
        }
    }
    
    private func sideBySideView(geometry: GeometryProxy) -> some View {
        HStack(spacing: 2) {
            // Image 1
            if let uiImage1 = image1.uiImage {
                VStack {
                    Image(uiImage: uiImage1)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width / 2)
                        .scaleEffect(scale)
                        .offset(offset)
                        .frame(width: geometry.size.width / 2)
                        .clipped()
                    
                    Text(image1.captureDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .padding(4)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .frame(width: geometry.size.width / 2)
            }
            
            Divider()
            
            // Image 2
            if let uiImage2 = image2.uiImage {
                VStack {
                    Image(uiImage: uiImage2)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width / 2)
                        .scaleEffect(scale)
                        .offset(offset)
                        .frame(width: geometry.size.width / 2)
                        .clipped()
                    
                    Text(image2.captureDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .padding(4)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .frame(width: geometry.size.width / 2)
            }
        }
        .gesture(
            MagnificationGesture()
                .onChanged { value in
                    scale = lastScale * value
                }
                .onEnded { _ in
                    // Limit scale between 1x and 5x
                    scale = min(max(scale, 1.0), 5.0)
                    lastScale = scale
                }
        )
        .simultaneousGesture(
            DragGesture()
                .onChanged { value in
                    let newOffset = CGSize(
                        width: lastOffset.width + value.translation.width,
                        height: lastOffset.height + value.translation.height
                    )
                    // Limit vertical offset to prevent covering the picker
                    let maxVerticalOffset = (geometry.size.height * (scale - 1)) / 2
                    offset = CGSize(
                        width: newOffset.width,
                        height: min(newOffset.height, maxVerticalOffset)
                    )
                }
                .onEnded { _ in
                    lastOffset = offset
                }
        )
    }
    
    private func overlayView(geometry: GeometryProxy) -> some View {
        ZStack {
            // Images with zoom and pan gestures
            ZStack {
                // Base image (older)
                if let uiImage1 = image1.uiImage {
                    Image(uiImage: uiImage1)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width)
                        .scaleEffect(scale)
                        .offset(offset)
                }
                
                // Overlay image (newer) with mask
                if let uiImage2 = image2.uiImage {
                    GeometryReader { geo in
                        Image(uiImage: uiImage2)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width)
                            .scaleEffect(scale)
                            .offset(offset)
                            .mask(
                                Rectangle()
                                    .frame(width: geo.size.width * sliderPosition)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            )
                    }
                }
            }
            .clipped()
            .contentShape(Rectangle())
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = lastScale * value
                    }
                    .onEnded { _ in
                        // Limit scale between 1x and 5x
                        scale = min(max(scale, 1.0), 5.0)
                        lastScale = scale
                    }
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        let newOffset = CGSize(
                            width: lastOffset.width + value.translation.width,
                            height: lastOffset.height + value.translation.height
                        )
                        // Limit vertical offset to prevent covering the picker
                        let maxVerticalOffset = (geometry.size.height * (scale - 1)) / 2
                        offset = CGSize(
                            width: newOffset.width,
                            height: min(newOffset.height, maxVerticalOffset)
                        )
                    }
                    .onEnded { _ in
                        lastOffset = offset
                    }
            )
            
            // Slider line overlay - separate layer with high priority gesture
            GeometryReader { geo in
                HStack(spacing: 0) {
                    // Invisible touch area for slider
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: max(44, geo.size.width * sliderPosition + 22))
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let newPosition = value.location.x / geo.size.width
                                    sliderPosition = min(max(newPosition, 0), 1)
                                }
                        )
                    
                    Spacer()
                }
                
                // Visual slider line
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 3)
                    .shadow(radius: 2)
                    .offset(x: geo.size.width * sliderPosition - 1.5)
                    .allowsHitTesting(false)
                
                // Visual slider handle
                Circle()
                    .fill(Color.white)
                    .frame(width: 30, height: 30)
                    .shadow(radius: 3)
                    .offset(x: geo.size.width * sliderPosition - 15)
                    .allowsHitTesting(false)
            }
        }
    }
    
    private var imageInfoView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Älteres Bild")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(image1.captureDate.formatted(date: .long, time: .shortened))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Neueres Bild")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(image2.captureDate.formatted(date: .long, time: .shortened))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            
            // Time difference
            if let daysDifference = Calendar.current.dateComponents([.day], from: image1.captureDate, to: image2.captureDate).day {
                Text("Zeitunterschied: \(daysDifference) Tage")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        if let image1 = MoleImage(image: UIImage(systemName: "photo")!),
           let image2 = MoleImage(image: UIImage(systemName: "photo.fill")!) {
            ComparisonView(image1: image1, image2: image2)
        }
    }
}