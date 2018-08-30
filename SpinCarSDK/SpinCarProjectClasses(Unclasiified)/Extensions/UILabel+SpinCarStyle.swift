import UIKit

extension UILabel {
    
    func spinCarStyle(withFontSize: CGFloat) -> UILabel {
        let stylizedLabel = UILabel()
        stylizedLabel.lineBreakMode = .byWordWrapping
        stylizedLabel.textAlignment = .center
        let textContent = self.text ?? ""
        let textString = NSMutableAttributedString(
            string: textContent,
            attributes: [
                NSAttributedStringKey.font: UIFont.spinCarFont(size: withFontSize, style: .Light)
            ]
        )
        let textRange = NSRange(location: 0, length: textString.length)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 1.38
        textString.addAttribute(NSAttributedStringKey.paragraphStyle, value: paragraphStyle, range: textRange)
        stylizedLabel.attributedText = textString
        stylizedLabel.textColor = UIColor.gray
        stylizedLabel.sizeToFit()
        return stylizedLabel
    }

}
