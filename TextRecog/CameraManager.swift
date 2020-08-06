//
//  CameraManager.swift
//  TextRecog
//
//  Created by scchn on 2020/8/6.
//  Copyright © 2020 scchn. All rights reserved.
//

import AVFoundation

extension AVCaptureDevice {
    func dimensions() -> CGSize {
        let dims = CMVideoFormatDescriptionGetDimensions(activeFormat.formatDescription)
        return CGSize(width: Int(dims.width), height: Int(dims.height))
    }
}

final class CameraManager: NSObject {
    
    private let session = AVCaptureSession()
    private var cameraInput: AVCaptureDeviceInput?
    private var videoDataOutput = AVCaptureVideoDataOutput()
    
    var cameras: [AVCaptureDevice] { devices(with: .video) }
    var activeCamera: AVCaptureDevice? {
        get { cameraInput?.device }
        set { setActiveCamera(newValue) }
    }
    
    var videoDataHandler: ((CMSampleBuffer) -> Void)?
    
    override init() {
        super.init()
        setupVideoOutput()
    }
    
    private func setupVideoOutput() {
        videoDataOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.setSampleBufferDelegate(self,
                                                queue: DispatchQueue(label: "camera_frame_processing_queue"))
        session.addOutput(self.videoDataOutput)
        
        guard let connection = self.videoDataOutput.connection(with: AVMediaType.video),
            connection.isVideoOrientationSupported else { return }
        
        connection.videoOrientation = .portrait
    }
    
    private func devices(with type: AVMediaType) -> [AVCaptureDevice] {
        let sess = AVCaptureDevice.DiscoverySession(deviceTypes: [.externalUnknown],
                                                    mediaType: type,
                                                    position: .unspecified)
        return sess.devices
    }
    
    private func setActiveCamera(_ camera: AVCaptureDevice?) {
        session.beginConfiguration()
        
        if let input = cameraInput {
            session.removeInput(input)
            cameraInput = nil
        }
        
        if let camera = camera,
            let input = try? AVCaptureDeviceInput(device: camera),
            session.canAddInput(input)
        {
            session.addInput(input)
            cameraInput = input
        }
        
        session.commitConfiguration()
    }
    
    func start() {
        session.startRunning()
    }
    
    func stop() {
        session.stopRunning()
    }
    
    func generatePreviewLayer() -> AVCaptureVideoPreviewLayer {
        .init(session: session)
    }
    
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection)
    {
        videoDataHandler?(sampleBuffer)
    }
}
