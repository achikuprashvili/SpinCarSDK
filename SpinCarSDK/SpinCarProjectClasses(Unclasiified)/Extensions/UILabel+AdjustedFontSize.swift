//
// UILabel+AdjustedFontSize.swift
// SpinCar
//
import UIKit
extension UILabel {
    
    func getApproximateFontSizeAfterAutoAdjust() -> CGFloat {
        let unadjustedTextSize = self.text?.size(withAttributes: [NSAttributedStringKey.font : self.font])
        let unadjustedWidth = unadjustedTextSize?.width ?? 16
        var scaleFactor = self.frame.size.width/unadjustedWidth
        if (!self.adjustsFontSizeToFitWidth || self.minimumScaleFactor >= 1.0 || scaleFactor >= 1.0) {
            return self.font.pointSize
        }
        scaleFactor = max(scaleFactor, self.minimumScaleFactor)
        return self.font.pointSize * scaleFactor
    }
    
}
