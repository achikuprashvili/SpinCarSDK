enum FontSyle: String {
    case Regular = "Regular"
    case Bold = "Bold"
    case BoldItalic = "BoldItalic"
    case ExtraBold = "ExtraBold"
    case ExtraBoldItalic = "ExtraBoldItalic"
    case Italic = "Italic"
    case Light = "Light"
    case LightItalic = "LightItalic"
    case SemiBold = "SemiBold"
    case SemiBoldItalic = "SemiBoldItalic"
}
import UIKit
extension UIFont {
    
    class func spinCarFont(size : CGFloat, style: FontSyle) -> UIFont {
        return UIFont(name: "OpenSans-\(style.rawValue)", size: size) ?? UIFont()
    }
    
}
