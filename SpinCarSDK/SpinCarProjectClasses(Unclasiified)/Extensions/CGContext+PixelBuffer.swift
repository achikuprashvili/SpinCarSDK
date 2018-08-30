//
//  CGContextExtension.swift
//  SpinCarAR
//
//  Created by Alex Rablau on 2/27/18.
//  Copyright © 2018 Rablau. All rights reserved.
//

import Foundation
import CoreGraphics
import UIKit
public func CGContextCreate(pixelBuffer: CVPixelBuffer) -> CGContext?{
  let width = CVPixelBufferGetWidth(pixelBuffer)
  let height = CVPixelBufferGetHeight(pixelBuffer)
  let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
  let pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)

  var colorSpace : CGColorSpace?
  var bitmapInfo : UInt32 = 0
  if pixelFormat == kCVPixelFormatType_OneComponent8 {
    colorSpace = CGColorSpaceCreateDeviceGray()
    bitmapInfo = CGImageAlphaInfo.none.rawValue
  }
  else {
    colorSpace = CGColorSpaceCreateDeviceRGB()
    bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue
  }
  
  CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
  let address = CVPixelBufferGetBaseAddress(pixelBuffer)
  
  let context = CGContext(data: address,
                          width: width,
                          height: height,
                          bitsPerComponent: 8,
                          bytesPerRow: bytesPerRow,
                          space: colorSpace!,
                          bitmapInfo: bitmapInfo)
  
  CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
  
  return context
}
