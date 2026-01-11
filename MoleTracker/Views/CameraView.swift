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
    
    var body: some View {
        ZStack {
            if cameraService.isAuthorized && cameraService.isCameraReady {
                CameraPreviewView(session: cameraService.previewLayer.session!)
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    // Capture button
                    Button(action: {
                        cameraService.capturePhoto()
                    }) {
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
            
            // Small delay to ensure preview layer is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                cameraService.startSession()
            }
        }
        .onDisappear {
            cameraService.stopSession()
            cameraService.onPhotoCaptured = nil
        }
    }
}

// MARK: - Camera Preview View
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        context.coordinator.previewLayer = previewLayer
                return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = context.coordinator.previewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}

#Preview {
    NavigationStack {
        CameraView { image in
            print("Image captured: \(image.size)")
        }
    }
}
