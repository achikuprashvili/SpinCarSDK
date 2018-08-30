import UIKit

extension UITableViewController {
    
    // TODO: Extraneous function. Refactor settings subsection VCs and MultiUserAccounts VC to subclass SpinCarViewController and use its setUpTitle function.
    func setupTitleWith(localizedStringTitle: String) {
        let titleLabel = UILabel()
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.text = NSLocalizedString(localizedStringTitle, comment: "Title for View Controller.")
        self.navigationItem.titleView = titleLabel.spinCarStyle(withFontSize: 21)
    }
    
}
