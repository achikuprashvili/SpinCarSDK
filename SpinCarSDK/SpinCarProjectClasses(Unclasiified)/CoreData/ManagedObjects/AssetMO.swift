//
//  AssetMO.swift
//  SpinCar
//
//  Copyright © 2016 SpinCar. All rights reserved.
//

import Foundation

extension AssetMO {
    @objc var basePath: NSURL? {
        if let view = self.view, let viewPath = view.fullURL {
            return viewPath
        }
        return nil
    }
    var fullURL: NSURL? {
        get {
            if let basePath = self.basePath, let filePath = self.filePath {
                return basePath.appendingPathComponent(filePath) as NSURL?
            }
            return nil
        }
    }
    var fullThumbnailPath: NSURL? {
        if let basePath = self.basePath, let thumbnailPath = self.thumbnailPath {
            return basePath.appendingPathComponent(thumbnailPath) as NSURL?
        }
        return nil
    }
    
    override func didChangeValue(forKey key: String) {
        super.didChangeValue(forKey: key)
        if key == "filePath" {
            if let fullURL = self.fullURL?.path {
                let etag = CommonHelpers.CommonHelper.fileMD5(fullURL)
                self.setValue(etag, forKey: "etag")
            }
        }
    }
    
    override func prepareForDeletion() {
        super.prepareForDeletion()
        if self.isDeleted {
            let logger = SpinCarCrashlyticsLogger.SpinCarLogger
            let fileManager = FileManager.default
            if let fullURL = self.fullURL {
                do {
                    try fileManager.removeItem(at: fullURL as URL)
                } catch let error as NSError {
                    logger.log("Unable to remove item at url \(fullURL): %@", varargs: [error])
                }
            }
            if let fullThumbnailPath = self.fullThumbnailPath {
                do {
                    try fileManager.removeItem(at: fullThumbnailPath as URL)
                } catch let error as NSError {
                    logger.log("Unable to remove thumbnail item at url \(fullThumbnailPath): %@", varargs: [error])
                }
            }
        }
    }
    
    func fileExists() -> Bool {
        let fileManager = FileManager.default
        if let fullURL = self.fullURL {
            return fileManager.fileExists(atPath: fullURL.path!)
        }
        return false
    }
}
