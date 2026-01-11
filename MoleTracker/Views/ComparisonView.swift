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
    
    @State private var comparisonMode: ComparisonMode = .sideBySide
    @State private var sliderPosition: CGFloat = 0.5
    @State private var scale1: CGFloat = 1.0
    @State private var scale2: CGFloat = 1.0
    
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
        VStack(spacing: 0) {
            // Mode Picker
            Picker("Vergleichsmodus", selection: $comparisonMode) {
                ForEach(ComparisonMode.allCases, id: \.self) { mode in
                    Label(mode.rawValue, systemImage: mode.icon)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
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
        .navigationTitle("Bildvergleich")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func sideBySideView(geometry: GeometryProxy) -> some View {
        HStack(spacing: 2) {
            // Image 1
            if let uiImage1 = image1.uiImage {
                VStack {
                    Image(uiImage: uiImage1)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale1)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale1 = value
                                }
                        )
                    
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
                        .scaleEffect(scale2)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale2 = value
                                }
                        )
                    
                    Text(image2.captureDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .padding(4)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .frame(width: geometry.size.width / 2)
            }
        }
    }
    
    private func overlayView(geometry: GeometryProxy) -> some View {
        ZStack {
            // Base image (older)
            if let uiImage1 = image1.uiImage {
                Image(uiImage: uiImage1)
                    .resizable()
                    .scaledToFit()
                    .frame(width: geometry.size.width)
            }
            
            // Overlay image (newer) with slider
            GeometryReader { geo in
                if let uiImage2 = image2.uiImage {
                    HStack(spacing: 0) {
                        Image(uiImage: uiImage2)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width)
                            .mask(
                                Rectangle()
                                    .frame(width: geo.size.width * sliderPosition)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            )
                        
                        Spacer()
                    }
                }
                
                // Slider line
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 3)
                    .shadow(radius: 2)
                    .offset(x: geo.size.width * sliderPosition - 1.5)
                    .overlay(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 30, height: 30)
                            .shadow(radius: 3)
                            .offset(x: geo.size.width * sliderPosition - 15)
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newPosition = value.location.x / geo.size.width
                                sliderPosition = min(max(newPosition, 0), 1)
                            }
                    )
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