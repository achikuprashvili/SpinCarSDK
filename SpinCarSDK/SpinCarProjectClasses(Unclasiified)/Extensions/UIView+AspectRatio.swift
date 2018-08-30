//
//  UIView+AspectRatio.swift
//  SpinCar
//

import Foundation
import UIKit
enum AspectRatio: CGFloat {
    case FourThree
    case SixteenNine
}

extension UIView {
    
    func resizeToAspectRatio(_ ratio: AspectRatio) {
        let minDimension = min(self.bounds.width, self.bounds.height)
        var maxDimension = max(self.bounds.width, self.bounds.height)
        
        switch ratio {
            case .FourThree:
                maxDimension = 4 * minDimension/3.0
            case .SixteenNine:
                maxDimension = 16 * minDimension/9.0
        }
        
        let newWidth = self.bounds.width == minDimension ? minDimension : maxDimension
        let newHeight = self.bounds.height == minDimension ? minDimension : maxDimension
        self.frame = CGRect(origin: self.frame.origin, size: CGSize(width: newWidth, height: newHeight))
    }
    
    func isAspectRatio(_ ratio: AspectRatio) -> Bool {
        let minDimension = min(self.bounds.width, self.bounds.height)
        var maxDimension = max(self.bounds.width, self.bounds.height)
        
        switch ratio {
            case .FourThree:
                return maxDimension == 4 * minDimension/3.0
            case .SixteenNine:
                return maxDimension == 16 * minDimension/9.0
        }
        
        return false
    }
}
