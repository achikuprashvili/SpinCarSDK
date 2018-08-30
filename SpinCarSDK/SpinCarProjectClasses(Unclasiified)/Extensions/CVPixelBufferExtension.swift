/**
 * Copyright (c) 2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import AVFoundation
import UIKit
import VideoToolbox

// Create a buffer compatible with core graphics for drawing
public func CVPixelBufferCreateCGBuffer(_ width: Int, _ height: Int, _ format: OSType, _ pixelBufferOut: UnsafeMutablePointer<CVPixelBuffer?>) -> CVReturn {
  let keys: [CFString] = [kCVPixelBufferCGImageCompatibilityKey, kCVPixelBufferCGBitmapContextCompatibilityKey]
  let values: [CFTypeRef] = [kCFBooleanTrue, kCFBooleanTrue]
  let keysPointer = UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: 1)
  let valuesPointer =  UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: 1)
  keysPointer.initialize(to: keys)
  valuesPointer.initialize(to: values)
  let options = CFDictionaryCreate(kCFAllocatorDefault, keysPointer, valuesPointer, keys.count, nil, nil)
  
  return CVPixelBufferCreate(kCFAllocatorDefault, width, height, format, options, pixelBufferOut)
}

extension CVPixelBuffer {
  
  func normalize() {
    
    let width = CVPixelBufferGetWidth(self)
    let height = CVPixelBufferGetHeight(self)
    
    CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
    let floatBuffer = unsafeBitCast(CVPixelBufferGetBaseAddress(self), to: UnsafeMutablePointer<Float>.self)
    
    var minPixel: Float = Float.greatestFiniteMagnitude
    var maxPixel: Float = 0.0
    
    for y in 0 ..< height {
      for x in 0 ..< width {
        let pixel = floatBuffer[y * width + x]
        if pixel < minPixel {
          minPixel = pixel
        }
        if pixel > maxPixel {
          maxPixel = pixel
        }
      }
    }
    
    let range = maxPixel - minPixel
    
    for y in 0 ..< height {
      for x in 0 ..< width {
        let pixel = floatBuffer[y * width + x]
        floatBuffer[y * width + x] = (pixel - minPixel) / range
      }
    }
    
    CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
  }
  
  func resize(width: Int, height: Int) -> CVPixelBuffer?{
    // Scale CVPixelBuffer using Core Graphics for efficieny
    var cgImage : CGImage? = nil
    VTCreateCGImageFromCVPixelBuffer(self, nil, &cgImage)
    
    guard cgImage != nil else {
      print("Could not create cgImage from pixel buffer")
      return nil
    }

    let colorSpace = cgImage!.colorSpace
    let bitmapInfo = cgImage!.bitmapInfo
    let bitsPerComponent = cgImage!.bitsPerComponent
    
    let bytesPerRow = width * 4
    
    let keys: [CFString] = [kCVPixelBufferCGImageCompatibilityKey, kCVPixelBufferCGBitmapContextCompatibilityKey]
    let values: [CFTypeRef] = [kCFBooleanTrue, kCFBooleanTrue]
    let keysPointer = UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: 1)
    let valuesPointer =  UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: 1)
    keysPointer.initialize(to: keys)
    valuesPointer.initialize(to: values)
    let options = CFDictionaryCreate(kCFAllocatorDefault, keysPointer, valuesPointer, keys.count, nil, nil)
    
    var scaledPixelBuffer: CVPixelBuffer?
    var result = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, options, &scaledPixelBuffer)
    
    CVPixelBufferLockBaseAddress(scaledPixelBuffer!, CVPixelBufferLockFlags(rawValue: 0));
    let bufferAddress = CVPixelBufferGetBaseAddress(scaledPixelBuffer!);
    
    let scaleContext = CGContext(data: bufferAddress, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace!, bitmapInfo: bitmapInfo.rawValue)!
    scaleContext.interpolationQuality = .none
    
    let drawRect = CGRect(x: 0, y: 0, width: width, height: height)
    scaleContext.draw(cgImage!, in: drawRect, byTiling: false)
    
    CVPixelBufferUnlockBaseAddress(scaledPixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

    return scaledPixelBuffer
  }
  
  func copy() -> CVPixelBuffer? {
    let width = CVPixelBufferGetWidth(self)
    let height = CVPixelBufferGetHeight(self)
    let format = CVPixelBufferGetPixelFormatType(self)
    var pixelBufferCopyOptional:CVPixelBuffer?
    CVPixelBufferCreate(nil, width, height, format, nil, &pixelBufferCopyOptional)
    if let pixelBufferCopy = pixelBufferCopyOptional {
      CVPixelBufferLockBaseAddress(self, .readOnly)
      CVPixelBufferLockBaseAddress(pixelBufferCopy, .init(rawValue: 0))
      let baseAddress = CVPixelBufferGetBaseAddress(self)
      let dataSize = CVPixelBufferGetDataSize(self)
      //print("dataSize: \(dataSize)")
      let target = CVPixelBufferGetBaseAddress(pixelBufferCopy)
      memcpy(target, baseAddress, dataSize)
      CVPixelBufferUnlockBaseAddress(pixelBufferCopy, .init(rawValue: 0))
      CVPixelBufferUnlockBaseAddress(self, .readOnly)
    }
    return pixelBufferCopyOptional
  }
}
