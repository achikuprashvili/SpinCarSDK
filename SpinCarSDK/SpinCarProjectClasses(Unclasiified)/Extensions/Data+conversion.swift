//
//  DataExtensions.swift
//  SpinCarAR
//
//  Created by Alex Rablau on 1/9/18.
//  Copyright © 2018 Rablau. All rights reserved.
//

import Foundation

extension Data {
  
  init<T>(from value: T) {
    var value = value
    self.init(buffer: UnsafeBufferPointer(start: &value, count: 1))
  }
  
  func to<T>(type: T.Type) -> T {
    return self.withUnsafeBytes { $0.pointee }
  }
  
  init<T>(fromArray values: [T]) {
    var values = values
    self.init(buffer: UnsafeBufferPointer(start: &values, count: values.count))
  }
  
  func toArray<T>(type: T.Type) -> [T] {
    return self.withUnsafeBytes {
      [T](UnsafeBufferPointer(start: $0, count: self.count/MemoryLayout<T>.stride))
    }
  }
}
