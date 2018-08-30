//
//  UIImage+CVPixelBuffer.swift
//  SpinCarAR
//
//  Created by Alex Rablau on 1/4/18.
//  Copyright © 2018 Rablau. All rights reserved.
//

import UIKit
import VideoToolbox
import CoreGraphics

extension UIImage {
  /**
   Resizes the image to width x height and converts it to an RGB CVPixelBuffer.
   */
  public func pixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
    return pixelBuffer(width: width, height: height,
                       pixelFormatType: kCVPixelFormatType_32ARGB,
                       colorSpace: CGColorSpaceCreateDeviceRGB(),
                       alphaInfo: .noneSkipFirst)
  }
  
  /**
   Resizes the image to width x height and converts it to a grayscale CVPixelBuffer.
   */
  public func pixelBufferGray(width: Int, height: Int) -> CVPixelBuffer? {
    return pixelBuffer(width: width, height: height,
                       pixelFormatType: kCVPixelFormatType_OneComponent8,
                       colorSpace: CGColorSpaceCreateDeviceGray(),
                       alphaInfo: .none)
  }
  
  func pixelBuffer(width: Int, height: Int, pixelFormatType: OSType,
                   colorSpace: CGColorSpace, alphaInfo: CGImageAlphaInfo) -> CVPixelBuffer? {
    var maybePixelBuffer: CVPixelBuffer?
    let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                 kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue]
    let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                     width,
                                     height,
                                     pixelFormatType,
                                     attrs as CFDictionary,
                                     &maybePixelBuffer)
    
    guard status == kCVReturnSuccess, let pixelBuffer = maybePixelBuffer else {
      return nil
    }
    
    CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
    let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)
    
    guard let context = CGContext(data: pixelData,
                                  width: width,
                                  height: height,
                                  bitsPerComponent: 8,
                                  bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                  space: colorSpace,
                                  bitmapInfo: alphaInfo.rawValue)
      else {
        return nil
    }
    
    UIGraphicsPushContext(context)
    context.translateBy(x: 0, y: CGFloat(height))
    context.scaleBy(x: 1, y: -1)
    self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
    UIGraphicsPopContext()
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
    return pixelBuffer
  }
}

extension UIImage {
  /**
   Creates a new UIImage from a CVPixelBuffer.
   NOTE: This only works for RGB pixel buffers, not for grayscale.
   */
  public convenience init?(pixelBuffer: CVPixelBuffer) {
//    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
//
//    let tempContext = CIContext()
//
//    let rect = CGRect.init(x: 0, y: 0,
//                           width: CVPixelBufferGetWidth(pixelBuffer),
//                           height: CVPixelBufferGetHeight(pixelBuffer))
//
//    let cgImage = tempContext.createCGImage(ciImage, from: rect)
//
//    self.init(cgImage: cgImage!)
    
    var cgImage: CGImage?
    VTCreateCGImageFromCVPixelBuffer(pixelBuffer, nil, &cgImage)
    
    if let cgImage = cgImage {
      self.init(cgImage: cgImage)
    } else {
      return nil
    }
  }
  
  /**
   Creates a new UIImage from a CVPixelBuffer, using Core Image.
   */
  public convenience init?(pixelBuffer: CVPixelBuffer, context: CIContext) {
    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
    let rect = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer),
                      height: CVPixelBufferGetHeight(pixelBuffer))
    
    if let cgImage = context.createCGImage(ciImage, from: rect) {
      self.init(cgImage: cgImage)
    } else {
      return nil
    }
  }
}
