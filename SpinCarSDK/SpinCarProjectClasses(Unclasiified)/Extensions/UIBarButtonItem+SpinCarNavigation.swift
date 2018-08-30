//
//  UIBarButtonItem+SpinCarNavigation.swift
//  SpinCar
//

import UIKit

extension UIBarButtonItem {

    func setUpConfirmButtonWith(localizedTitle: String) {
        self.title = NSLocalizedString(localizedTitle, comment: "Title for confirm-style button")
        let attributes = [NSAttributedStringKey.font: UIFont.spinCarFont(size: 14, style: .Regular),
                          NSAttributedStringKey.foregroundColor: UIColor(red: 0, green: 0.48, blue: 1, alpha: 1)]
        self.setTitleTextAttributes(attributes, for: .normal)
        self.setTitleTextAttributes(attributes, for: .selected)
    }

}
