//
//  CameraViewController.swift
//  opencv
//
//  Created by UMCios on 2023/03/17.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController {
    
    private var lastProcessedFrameTimestamp: CMTime = .zero
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private lazy var captureSession = AVCaptureSession()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        Task {
            await AVCaptureDevice.requestAccess(for: .video)
            // The user granted permission.
            setupCamera()
            setPreview()
        }
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        guard !captureSession.isRunning else {
            return
        }
        setCaptureSessionOutput()
        setCaptureSessionInput()
    }
    
    private func setCaptureSessionOutput() {
        captureSession.beginConfiguration()
        // When performing latency tests to determine ideal capture settings,
        // run the app in 'release' mode to get accurate performance metrics
        captureSession.sessionPreset = AVCaptureSession.Preset.medium
        
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [
            (kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA
        ]
        output.alwaysDiscardsLateVideoFrames = true
        let outputQueue = DispatchQueue(label: "streamingQueue")
        output.setSampleBufferDelegate(self, queue: outputQueue)
        guard captureSession.canAddOutput(output) else {
            print("Failed to add capture session output.")
            return
        }
        captureSession.addOutput(output)
        captureSession.commitConfiguration()
    }
    
    private func setCaptureSessionInput() {
        guard let device = captureDevice(forPosition: .back) else { return }
        do {
            captureSession.beginConfiguration()
            for input in captureSession.inputs {
                captureSession.removeInput(input)
            }
            let input = try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            captureSession.commitConfiguration()
        } catch {
            print("Failed to create capture device input: \(error.localizedDescription)")
        }
    }
    
    private func setPreview() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
    }

    private func captureDevice(forPosition position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        if #available(iOS 10.0, *) {
            let discoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera],
                mediaType: .video,
                position: .unspecified
            )
            return discoverySession.devices.first { $0.position == position }
        }
        return nil
    }
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let currentFrameTimestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        // Check if the current frame's timestamp is greater than the last processed frame's timestamp
        if currentFrameTimestamp > lastProcessedFrameTimestamp {
            // Update the last processed frame's timestamp
            lastProcessedFrameTimestamp = currentFrameTimestamp
            
        }
    }
}

