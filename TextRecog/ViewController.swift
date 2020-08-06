//
//  ViewController.swift
//  TextRecog
//
//  Created by scchn on 2020/8/6.
//  Copyright © 2020 scchn. All rights reserved.
//

import Cocoa
import AVFoundation
import Vision
import Accelerate

class ViewController: NSViewController {
    
    let cameraManager = CameraManager()
    let rectLayer = CAShapeLayer()
    var previewField: CGRect = .zero
    
    @IBOutlet weak var label: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        if let dimensions = cameraManager.activeCamera?.dimensions() {
            previewField = AVMakeRect(aspectRatio: dimensions, insideRect: self.view.bounds)
        }
    }
    
    func showAlert(title: String) {
        guard let window = view.window else { return }
        let alert = NSAlert()
        alert.messageText = title
        alert.beginSheetModal(for: window)
    }
    
    func setupCamera() {
        cameraManager.start()
        cameraManager.videoDataHandler = { [unowned self] sampleBuffer in
            self.detectTextRect(in: sampleBuffer)
        }
        
        let previewLayer = cameraManager.generatePreviewLayer()
        view.wantsLayer = true
        previewLayer.frame = view.bounds
        previewLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        previewLayer.backgroundColor = .black
        view.layer?.addSublayer(previewLayer)
        
        rectLayer.frame = view.bounds
        rectLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        rectLayer.strokeColor = NSColor.red.cgColor
        rectLayer.fillColor = .clear
        view.layer?.addSublayer(rectLayer)
        
        if let camera = cameraManager.cameras.first {
            cameraManager.activeCamera = camera
        } else {
            fatalError("Coundn't find cameras.")
        }
    }
    
    func detectTextRect(in sampleBuffer: CMSampleBuffer) {
        guard let image = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNDetectTextRectanglesRequest { [unowned self] request, _ in
            guard let results = request.results as? [VNRectangleObservation] else {
                return
            }
            self.handleDetectedRects(results: results, in: image)
        }
        do {
            let requestHandler = VNImageRequestHandler(cvPixelBuffer: image, options: [:])
            try requestHandler.perform([request])
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func handleDetectedRects(results: [VNRectangleObservation], in pixelBuffer: CVPixelBuffer) {
        for result in results {
            self.recognizeText(in: pixelBuffer, regionOfInterest: result.boundingBox)
            break
        }
        
        DispatchQueue.main.async {
            let path = CGMutablePath()
            
            for result in results {
                var corners = [result.topLeft, result.topRight, result.bottomRight, result.bottomLeft]
                corners = corners.map { point in
                    CGPoint(x: point.x * self.previewField.width + self.previewField.origin.x,
                            y: point.y * self.previewField.height + self.previewField.origin.y)
                }
                path.addLines(between: corners)
                path.closeSubpath()
                break
            }
            
            self.rectLayer.path = path
        }
    }
    
    func recognizeText(in image: CVPixelBuffer, regionOfInterest: CGRect) {
        let request = VNRecognizeTextRequest { request, _ in
            guard let result = request.results?.first as? VNRecognizedTextObservation else {
                DispatchQueue.main.async {
                    self.label.stringValue = ""
                }
                return
            }
            if let candidate = result.topCandidates(1).first {
                DispatchQueue.main.async {
                    self.label.stringValue = candidate.string
                }
            }
        }
        request.recognitionLevel = .fast
        request.regionOfInterest = regionOfInterest
        do {
            let requestHandler = VNImageRequestHandler(cvPixelBuffer: image, options: [:])
            try requestHandler.perform([request])
        } catch {
            print(error.localizedDescription)
        }
    }

}

