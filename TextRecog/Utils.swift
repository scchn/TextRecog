//
//  Utils.swift
//  TextRecog
//
//  Created by scchn on 2020/8/6.
//  Copyright © 2020 scchn. All rights reserved.
//

import Cocoa

extension CVPixelBuffer {
    
    func crop(to rect: CGRect) -> CVPixelBuffer? {
        defer { CVPixelBufferUnlockBaseAddress(self, .readOnly) }
        CVPixelBufferLockBaseAddress(self, .readOnly)

        guard var baseAddress = CVPixelBufferGetBaseAddress(self) else { return nil }
        
        let bytesPerRow = CVPixelBufferGetBytesPerRow(self)
        let cropWidth = Int(rect.width)
        let cropHeight = Int(rect.height)
        let offset = Int(rect.origin.y) * bytesPerRow + Int(rect.origin.x) * 32 /*bytesPerPixel*/
        baseAddress = baseAddress + offset
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: baseAddress, width: cropWidth, height: cropHeight, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        
        var pixelBuffer: CVPixelBuffer?
        let options = [kCVPixelBufferCGImageCompatibilityKey:true,
                       kCVPixelBufferCGBitmapContextCompatibilityKey:true]
        let status =
        CVPixelBufferCreateWithBytes(kCFAllocatorDefault,
                                     cropWidth,
                                     cropHeight,
                                     kCVPixelFormatType_32BGRA,
                                     baseAddress,
                                     Int(bytesPerRow),
                                     nil, nil,
                                     options as CFDictionary, &pixelBuffer)
        
        return status != 0 ? nil : pixelBuffer
    }
    
}
