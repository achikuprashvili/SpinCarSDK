import UIKit
extension UIDevice {
    
    var isIPhoneX: Bool {
        return UIScreen.main.nativeBounds.height == 2436
    }
    
    var isIPhone7Or8: Bool {
        return UIScreen.main.nativeBounds.height == 1334
    }
    
    var isIpad: Bool {
        return self.userInterfaceIdiom == .pad
    }
    
}

