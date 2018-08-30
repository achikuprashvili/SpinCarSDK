//
//  UIScrollView+ScrollingCheck.swift
//  SpinCar
//

import Foundation
import UIKit
extension UIView {
    
    func isScrolling () -> Bool {
        if let scrollView = self as? UIScrollView {
            if scrollView.isDragging || scrollView.isDecelerating {
                return true
            }
        }
        
        for subview in self.subviews {
            if subview.isScrolling() {
                return true
            }
        }
        
        return false
    }
    
}
