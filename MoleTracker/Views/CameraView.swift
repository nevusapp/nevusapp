//
//  CameraView.swift
//  MoleTracker
//
//  Created on 06.01.2026.
//

import SwiftUI
import AVFoundation

struct CameraView: View {
    @ObservedObject private var cameraService = CameraService.shared
    @Environment(\.dismiss) private var dismiss

    let onImageCaptured: (UIImage) -> Void
    let referenceImage: UIImage?

    @State private var overlayOpacity: Double = 0.5
    @State private var showOverlay: Bool = true

    init(referenceImage: UIImage? = nil, onImageCaptured: @escaping (UIImage) -> Void) {
        self.referenceImage = referenceImage
        self.onImageCaptured = onImageCaptured
    }

    var body: some View {
        Group {
            if cameraService.isAuthorized && cameraService.isCameraReady {
                CameraContentView(
                    session: cameraService.previewLayer.session!,
                    referenceImage: referenceImage,
                    overlayOpacity: $overlayOpacity,
                    showOverlay: $showOverlay,
                    onCapture: { cameraService.capturePhoto() }
                )
            } else if let error = cameraService.error {
                VStack(spacing: 20) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)

                    Text(error.localizedDescription)
                        .multilineTextAlignment(.center)
                        .padding()

                    Button("Einstellungen öffnen") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else {
                ProgressView("Kamera wird vorbereitet...")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Abbrechen") {
                    dismiss()
                }
            }
        }
        .onAppear {
            // Set up direct callback
            cameraService.onPhotoCaptured = { [weak cameraService] image in
                print("🎯 [DEBUG] onPhotoCaptured callback triggered at \(Date())")

                // Stop session immediately
                print("📷 [DEBUG] Stopping session at \(Date())")
                cameraService?.stopSession()

                // Dismiss immediately
                print("👋 [DEBUG] Calling dismiss() at \(Date())")
                dismiss()

                // Process image in background
                Task.detached(priority: .userInitiated) {
                    print("➕ [DEBUG] Calling onImageCaptured at \(Date())")
                    await MainActor.run {
                        onImageCaptured(image)
                        print("✅ [DEBUG] onImageCaptured completed at \(Date())")
                    }
                }
            }

            // Start session immediately - no delay needed
            cameraService.startSession()
        }
        .onDisappear {
            cameraService.stopSession()
            cameraService.onPhotoCaptured = nil
        }
    }
}
// MARK: - Overlay Image View

// MARK: - Camera Content View (Isolated from parent state changes)
struct CameraContentView: View {
    let session: AVCaptureSession
    let referenceImage: UIImage?
    @Binding var overlayOpacity: Double
    @Binding var showOverlay: Bool
    let onCapture: () -> Void
    
    var body: some View {
        ZStack {
            // Camera preview as base layer - completely isolated
            CameraPreviewView(session: session)
                .ignoresSafeArea()
                .id("camera_preview")
            
            // Overlay content in separate layer
            if showOverlay, let refImage = referenceImage {
                OverlayImageView(image: refImage, opacity: overlayOpacity)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            
            // UI Controls in top layer
            VStack(spacing: 0) {
                // Top controls for overlay
                if referenceImage != nil {
                    VStack(spacing: 12) {
                        // Overlay controls container (centered)
                        HStack(spacing: 16) {
                            // Toggle overlay button
                            Button(action: {
                                withAnimation {
                                    showOverlay.toggle()
                                }
                            }) {
                                Image(systemName: showOverlay ? "eye.fill" : "eye.slash.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color.black.opacity(0.7))
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                            }

                            // Opacity slider (only when overlay is visible)
                            if showOverlay {
                                HStack(spacing: 8) {
                                    Text("Transparenz:")
                                        .font(.subheadline)
                                        .foregroundColor(.white)

                                    Slider(value: $overlayOpacity, in: 0.1...0.9)
                                        .tint(.white)

                                    Text("\(Int(overlayOpacity * 100))%")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                        .frame(width: 45)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(12)
                                .shadow(radius: 4)
                                .transition(.opacity)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 70)
                }

                Spacer()

                // Info text when overlay is active
                if referenceImage != nil && showOverlay {
                    Text("Richte die Kamera aus, bis das Overlay passt")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                        .padding(.bottom, 20)
                }

                // Capture button
                Button(action: onCapture) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 70, height: 70)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                                .frame(width: 80, height: 80)
                        )
                }
                .padding(.bottom, 40)
            }
        }
    }
}


// MARK: - Overlay Image View
struct OverlayImageView: View {
    let image: UIImage
    let opacity: Double
    
    var body: some View {
        GeometryReader { geometry in
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .opacity(opacity)
                .drawingGroup() // Render into offscreen buffer for smooth opacity changes
        }
    }
}


// MARK: - Camera Preview View
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    // Implement Equatable to prevent unnecessary updates
    static func == (lhs: CameraPreviewView, rhs: CameraPreviewView) -> Bool {
        // Sessions are the same object, so prevent any updates
        return lhs.session === rhs.session
    }

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.backgroundColor = .black
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        // Explicitly do nothing - prevent any updates
        // The session is set once in makeUIView and never changes
    }
    
    // Custom UIView subclass that properly manages the preview layer
    class PreviewView: UIView {
        override class var layerClass: AnyClass {
            return AVCaptureVideoPreviewLayer.self
        }
        
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            // The layer automatically resizes with the view
            // No manual frame updates needed
        }
    }
}

#Preview {
    NavigationStack {
        CameraView { image in
            print("Image captured: \(image.size)")
        }
    }
}


