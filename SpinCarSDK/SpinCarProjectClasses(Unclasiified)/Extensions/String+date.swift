import Foundation
extension String {
    
    func toDate() -> Date? {
        // Not robust or generalized. This helper function is only to be used for timestamp strings received from Suite's API.
        // Example format: "20170112213251"
        guard self != "" else {
            return nil
        }
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = "YYYYMMddHHmmss"
        return dateFormatter.date(from: self)
    }
    
}
