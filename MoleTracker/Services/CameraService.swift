//
//  CameraService.swift
//  MoleTracker
//
//  Created on 06.01.2026.
//

import AVFoundation
import UIKit
import SwiftUI
import Combine

@MainActor
class CameraService: NSObject, ObservableObject {
    static let shared = CameraService()
    
    @Published var capturedImage: UIImage?
    @Published var isAuthorized = false
    @Published var error: CameraError?
    @Published var isCameraReady = false
    
    // Direct callback for immediate response
    var onPhotoCaptured: ((UIImage) -> Void)?
    
    private let captureSession = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var currentPhotoSettings: AVCapturePhotoSettings?
    private var isSetupComplete = false
    
    private override init() {
        super.init()
        checkAuthorization()
    }
    
    func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    if granted {
                        self?.setupCamera()
                    } else {
                        self?.error = .accessDenied
                    }
                }
            }
        case .denied, .restricted:
            isAuthorized = false
            error = .accessDenied
        @unknown default:
            isAuthorized = false
        }
    }
    
    private func setupCamera() {
        // Only setup once
        guard !isSetupComplete else {
            DispatchQueue.main.async {
                self.isCameraReady = true
            }
            return
        }
        
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo
        
        // Setup video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(videoInput) else {
            error = .setupFailed
            captureSession.commitConfiguration()
            return
        }
        
        captureSession.addInput(videoInput)
        
        // Setup photo output
        guard captureSession.canAddOutput(photoOutput) else {
            error = .setupFailed
            captureSession.commitConfiguration()
            return
        }
        
        captureSession.addOutput(photoOutput)
        
        // Configure photo output
        if #available(iOS 16.0, *) {
            photoOutput.maxPhotoDimensions = CMVideoDimensions(width: 4032, height: 3024)
        } else {
            photoOutput.isHighResolutionCaptureEnabled = true
        }
        if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
            photoOutput.maxPhotoQualityPrioritization = .quality
        }
        
        captureSession.commitConfiguration()
        isSetupComplete = true
        
        DispatchQueue.main.async {
            self.isCameraReady = true
        }
    }
    
    func startSession() {
        // Ensure camera is authorized and ready before starting
        guard isAuthorized else {
            // If not authorized yet, wait a bit and try again
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.startSession()
            }
            return
        }
        
        guard isCameraReady else {
            // If not ready yet, wait a bit and try again
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.startSession()
            }
            return
        }
        
        guard !captureSession.isRunning else { return }
        
        Task.detached { [captureSession] in
            captureSession.startRunning()
        }
    }
    
    func stopSession() {
        guard captureSession.isRunning else { return }
        Task.detached { [captureSession] in
            captureSession.stopRunning()
        }
    }
    
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        
        if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
            settings.photoQualityPrioritization = .quality
        }
        
        currentPhotoSettings = settings
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    var previewLayer: AVCaptureVideoPreviewLayer {
        let layer = AVCaptureVideoPreviewLayer(session: captureSession)
        layer.videoGravity = .resizeAspectFill
        return layer
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraService: AVCapturePhotoCaptureDelegate {
    // nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    //     if let error = error {
    //         Task { @MainActor in
    //             self.error = .captureFailed(error.localizedDescription)
    //         }
    //         return
    //     }
        
        
    //     // Process image data on background thread
    //     Task.detached(priority: .userInitiated) {
    //         guard let imageData = photo.fileDataRepresentation(),
    //               let image = UIImage(data: imageData) else {
    //             await MainActor.run {
    //                 self.error = .invalidImage
    //             }
    //             return
    //         }
            
    //         // Set captured image on main thread
    //         await MainActor.run {
    //             self.capturedImage = image
    //         }
    //     }
    // }
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    print("📸 [DEBUG] photoOutput called at \(Date())")
    
    if let error = error {
        print("❌ [DEBUG] Error: \(error)")
        Task { @MainActor in
            self.error = .captureFailed(error.localizedDescription)
        }
        return
    }
    
    Task.detached(priority: .userInitiated) {
        print("🔄 [DEBUG] Starting image processing at \(Date())")
        
        guard let imageData = photo.fileDataRepresentation() else {
            print("❌ [DEBUG] Failed to get image data")
            await MainActor.run {
                self.error = .invalidImage
            }
            return
        }
        print("✅ [DEBUG] Got image data (\(imageData.count) bytes) at \(Date())")
        
        guard let image = UIImage(data: imageData) else {
            print("❌ [DEBUG] Failed to create UIImage")
            await MainActor.run {
                self.error = .invalidImage
            }
            return
        }
        print("✅ [DEBUG] Created UIImage at \(Date())")
        
        await MainActor.run {
            print("✅ [DEBUG] Calling onPhotoCaptured callback at \(Date())")
            self.onPhotoCaptured?(image)
            
            // Also set for backwards compatibility
            print("✅ [DEBUG] Setting capturedImage on MainActor at \(Date())")
            self.capturedImage = image
        }
    }
}
}

// MARK: - Camera Error
enum CameraError: LocalizedError {
    case accessDenied
    case setupFailed
    case captureFailed(String)
    case invalidImage
    
    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Kamera-Zugriff verweigert. Bitte erlauben Sie den Zugriff in den Einstellungen."
        case .setupFailed:
            return "Kamera konnte nicht initialisiert werden."
        case .captureFailed(let message):
            return "Foto konnte nicht aufgenommen werden: \(message)"
        case .invalidImage:
            return "Ungültiges Bild."
        }
    }
}
