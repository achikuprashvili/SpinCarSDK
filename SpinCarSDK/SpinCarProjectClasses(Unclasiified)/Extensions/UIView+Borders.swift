//
//  UIView+Borders.swift
//  SpinCar
//

import UIKit

extension UIView {
    func addBottomBorder(borderWidth: CGFloat, color: UIColor) {
        let border = CALayer()
        border.borderWidth = borderWidth
        border.borderColor = color.cgColor
        border.frame = CGRect(x: 0, y: self.frame.size.height - borderWidth, width: self.frame.size.width, height: borderWidth)
        self.layer.addSublayer(border)
    }
}
