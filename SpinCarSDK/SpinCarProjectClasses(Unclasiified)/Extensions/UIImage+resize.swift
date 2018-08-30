import UIKit

extension UIImage {
    func createThumbnailImage(targetSize: CGSize) -> UIImage? {
        let widthRatio = targetSize.width / self.size.width
        let heightRatio = targetSize.height / self.size.height
        let newSize = CGSize(width: self.size.width * widthRatio, height: self.size.height * heightRatio)
        let newSizeRect = CGRect(origin: .zero, size: newSize)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        self.draw(in: newSizeRect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
