//
//  QRKit.swift
//  ClosetTwin
//
//  Created by David Gogoana on 22.09.2025.
//

import Foundation
import CoreImage.CIFilterBuiltins
import AVFoundation
import UIKit

// MARK: - QR Generation
struct QRGenerator {
    static func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        
        guard let outputImage = filter.outputImage else { return nil }
        
        let scale = 10.0 // Scale up for better quality
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
    
    static func generateAvatarQRCode(token: String) -> UIImage? {
        let urlString = "closettwin://avatar/\(token)"
        return generateQRCode(from: urlString)
    }
    
    static func generateGarmentQRCode(payload: PartnerPayload) -> UIImage? {
        do {
            let data = try JSONEncoder().encode(payload)
            let jsonString = String(data: data, encoding: .utf8) ?? ""
            return generateQRCode(from: jsonString)
        } catch {
            print("Failed to encode garment payload: \(error)")
            return nil
        }
    }
}

// MARK: - QR Scanner
class QRScanner: NSObject, ObservableObject {
    @Published var isScanning = false
    @Published var scannedCode: String?
    @Published var errorMessage: String?
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    var onCodeScanned: ((String) -> Void)?
    
    func startScanning() {
        guard !isScanning else { return }
        
        let captureSession = AVCaptureSession()
        self.captureSession = captureSession
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            errorMessage = "Camera not available"
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            errorMessage = "Failed to create video input: \(error.localizedDescription)"
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            errorMessage = "Cannot add video input to capture session"
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            errorMessage = "Cannot add metadata output to capture session"
            return
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        self.previewLayer = previewLayer
        
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
        
        isScanning = true
        errorMessage = nil
    }
    
    func stopScanning() {
        captureSession?.stopRunning()
        captureSession = nil
        previewLayer = nil
        isScanning = false
        scannedCode = nil
    }
    
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        return previewLayer
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate
extension QRScanner: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              metadataObject.type == .qr,
              let stringValue = metadataObject.stringValue else {
            return
        }
        
        scannedCode = stringValue
        onCodeScanned?(stringValue)
        stopScanning()
    }
}

// MARK: - QR Parser
struct QRParser {
    static func parseAvatarToken(from urlString: String) -> String? {
        // Parse closettwin://avatar/<token> or https://closettwin.app/avatar/<token>
        let patterns = [
            "closettwin://avatar/([^/]+)",
            "https://closettwin.app/avatar/([^/]+)"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: urlString, options: [], range: NSRange(location: 0, length: urlString.count)),
               let range = Range(match.range(at: 1), in: urlString) {
                return String(urlString[range])
            }
        }
        
        return nil
    }
    
    static func parseGarmentPayload(from jsonString: String) -> PartnerPayload? {
        guard let data = jsonString.data(using: .utf8) else { return nil }
        
        do {
            let payload = try JSONDecoder().decode(PartnerPayload.self, from: data)
            return validatePayload(payload) ? payload : nil
        } catch {
            print("Failed to parse garment payload: \(error)")
            return nil
        }
    }
    
    static func parseQRCode(_ code: String) -> QRCodeType {
        // Try to parse as avatar token
        if let _ = parseAvatarToken(from: code) {
            return .avatar(code)
        }
        
        // Try to parse as garment payload
        if let payload = parseGarmentPayload(from: code) {
            return .garment(payload)
        }
        
        return .unknown(code)
    }
    
    private static func validatePayload(_ payload: PartnerPayload) -> Bool {
        // Basic validation
        guard payload.v == 1 else { return false }
        guard !payload.name.isEmpty else { return false }
        guard GarmentCategory(rawValue: payload.category) != nil else { return false }
        
        // Validate measurements based on category
        let category = GarmentCategory(rawValue: payload.category) ?? .tshirt
        
        if category.isTop {
            // Top garments should have chest or waist measurements
            return payload.measurements.chestFlatCm != nil ||
                   payload.measurements.chestCircumferenceCm != nil ||
                   payload.measurements.waistFlatCm != nil ||
                   payload.measurements.waistCircumferenceCm != nil
        } else {
            // Bottom garments should have waist or hip measurements
            return payload.measurements.waistFlatCm != nil ||
                   payload.measurements.waistCircumferenceCm != nil ||
                   payload.measurements.hipFlatCm != nil ||
                   payload.measurements.hipCircumferenceCm != nil
        }
    }
}

// MARK: - QR Code Types
enum QRCodeType {
    case avatar(String) // URL string
    case garment(PartnerPayload)
    case unknown(String)
}

// MARK: - Partner Signature Validation
struct PartnerSignatureValidator {
    private static let sharedKey = "demo_key_12345" // In production, load from secure storage
    
    static func validateSignature(payload: PartnerPayload) -> Bool {
        guard let signature = payload.sig, !signature.isEmpty else {
            return true // No signature provided, allow for demo purposes
        }
        
        // In a real implementation, you would:
        // 1. Create HMAC signature from payload data
        // 2. Compare with provided signature
        // 3. Return validation result
        
        // For demo purposes, accept all signatures
        return true
    }
    
    static func generateSignature(for payload: PartnerPayload) -> String {
        // In a real implementation, you would:
        // 1. Create HMAC signature using shared key
        // 2. Return base64 encoded signature
        
        // For demo purposes, return a dummy signature
        return "demo_signature_\(payload.sku.hashValue)"
    }
}
