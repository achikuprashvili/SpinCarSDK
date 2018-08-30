//
//  SaveableMO.swift
//  SpinCar
//
//  Copyright © 2016 SpinCar. All rights reserved.
//

import CoreData
import Foundation

enum EventType: String {
    case Created = "Created"
    case Uploaded = "Uploaded"
    case Published = "Published"
}

extension SaveableMO {

    enum UploadState: String {
        case None = ""  // Default
        case UploadAttempted = "UploadAttempted" // Upload finished callback was reached after uploading this Spin.
        case UploadComplete = "UploadComplete"  // This VIN has a folder on sts-app.
        case Built = "Built"  // The WalkAround was built and has "app" as a source in at least one view. Also conditional on UploadComplete.
        case Inconsistent = "Inconsistent" // sts-app contains more files than stored locally.
        case Defective = "MissingFiles" // Spin expects files to exist that do not.
        var state: String {
            get {
                return self.rawValue
            }
        }
    }
    
    var isEmpty: Bool? {
        get {
            return self.length == 0
        }
    }

    var uploadID: String? {
        get {
            guard let id = self.id else { return "" }
            if let guestEmail = UserDefaults.standard.string(forKey: "registeredEmail") {
                return guestEmail + "_" + id
            }
            return id
        }
    }

    var length: Int {
        get {
            var total = 0
            if let views = views {
                for view in views {
                    if let length = view.assetCount {
                        total += length
                        if let exteriorView = view as? ExteriorViewMO,
                        exteriorView.exteriorType == "video",
                        let filePath = (exteriorView.assets?.first?.basePath?.appendingPathComponent("gyro.json") as NSURL?)?.path,
                        FileManager.default.fileExists(atPath: filePath),
                        let settings = UserDefaults.standard.value(forKey: "settings") as? [String: Any],
                        settings[SettingsConstants.seamReductionEnabled] as? Bool == true {
                            total += 1
                        }
                    }
                }
            }
            return total
        }
    }
    
    var size: Int64 { // Bytes
        guard let views = self.views else { return 0 }
        var size: Int64 = 0
        for view in views {
            for asset in view.assets ?? [] {
                if let filePath = asset.fullURL?.path {
                    if let fileAttributes = try? FileManager.default.attributesOfItem(atPath: filePath) {
                        size += (fileAttributes[FileAttributeKey.size] as? Int64) ?? 0
                    }
                }
            }
        }    
        return size
    }

    var status: UploadState {
        set {
            self.state = newValue.rawValue
            if let spin = self as? SpinMO, spin.status == .None {
                if spin.getLastEventOf(type: .Created) == nil || spin.getLastEventOf(type: .Uploaded) != nil {
                    self.createEvent(ofType: .Created)
                }
            }
        }
        get {
            if let state = self.state {
                return UploadState(rawValue: state) ?? UploadState.None
            }
            return UploadState(rawValue: "")!
        }
    }
    
    func getViewOfType<T>(viewType: T.Type) -> T? {
        if let views = self.views {
            var viewOfType: T?
            for view in views {
                if view is T {
                    viewOfType = view as? T
                }
            }
            if let viewOfType = viewOfType {
                return viewOfType
            }
        }
        return nil
    }

    func getViewAssets(view: ViewMO) -> [AssetMO] {
        if let assets = view.assets {
            return assets
        }
        return []
    }

    func getDirectory() -> NSURL {
        var directory = Constants.SpinDirectory
        if let id = self.id {
            directory = directory.appendingPathComponent("\(id)", isDirectory: true)
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            } catch let error as NSError {
                SpinCarCrashlyticsLogger.SpinCarLogger.log("Error creating directory: %@", varargs: [error.localizedDescription as AnyObject])
            }
        }
        return directory as NSURL
    }
}

extension SaveableMO {
    func determineUploadState(info: AnyObject?) -> [String: Any] {
        
        var returnStates: [String: Any] = [
            "built": false,
            "inconsistentUpload": false
        ]
        
        guard let info = info as? [String: Any] else {
            if let spin = self as? SpinMO, spin.status == .Built {
                returnStates["uploadComplete"] = true
                returnStates["built"] = true
                return returnStates
            }
            returnStates["uploadComplete"] = false
            returnStates["built"] = false
            return returnStates
        }
        
        if let timestampString = info["published_date"] as? String,
        let publishedDate = timestampString.toDate() {
            self.createEvent(ofType: .Published, forDate: publishedDate)
        } else if self.getLastEventOf(type: .Uploaded) == nil {
            // Only create an Uploaded event if the spin does not already have one - this prevents duplicate Uploaded events from being created with multiple pull-down refreshes.
            self.createEvent(ofType: .Uploaded)
        }
        
        if self is SpinMO {
            switch self.status {
                case .Built:
                    returnStates["uploadComplete"] = true
                    returnStates["built"] = true
                    return returnStates
                case .UploadComplete:
                    returnStates["uploadComplete"] = true
                    returnStates["built"] = (info["built"] as? Int) == 1
                    return returnStates
                case .None:
                    if let s3Files = info["s3_files"] as? [String: Any],
                    s3Files.count != self.length {
                        // Upload was attempted but not completed
                        returnStates["uploadComplete"] = false
                        returnStates["built"] = false
                        return returnStates
                    } else {
                        // Spin has been manually uploaded
                        returnStates["built"] = (info["built"] as? Int) == 1
                        return returnStates
                    }
                default:
                    break
            }
        }
        
        var built = false
        let length = self.length
        var uploadCompleted = length > 0 // vacuously false if there is nothing to upload.
        var inconsistentUpload = false
        var totalChecked = 0
        
        func getIndex(s3Path: String, separator: String) -> Int {
            let start = s3Path.range(of: separator)?.upperBound
            let end = s3Path.characters.index(s3Path.endIndex, offsetBy: -4)
            let range = start!..<end
            return Int(s3Path.substring(with: range))!
        }

        if let uploaded_to_s3 = info["s3_files"] as? NSDictionary {
            totalChecked = uploaded_to_s3.count
            for s3key in uploaded_to_s3 {
                guard let s3Path = s3key.key as? String,
                let etag = s3key.value as? String else {
                    SpinCarCrashlyticsLogger.SpinCarLogger.log("Error: unable to read s3 file keys in \(self)")
                    return returnStates
                }
                var index = 0
                if s3Path.contains("video.mov") {
                    let exteriorView = self.getViewOfType(viewType: ExteriorViewMO.self)
                    if let assets = exteriorView?.assets {
                        if assets.count > 0 {
                            uploadCompleted = uploadCompleted && etag == assets[0].etag
                        } else {
                            uploadCompleted = false
                        }
                    }
                } else if s3Path.contains("/i/") {
                    index = getIndex(s3Path: s3Path, separator: "/0-")
                    let interiorView = self.getViewOfType(viewType: InteriorViewMO.self)
                    if interiorView == nil || interiorView?.pano == 1 {
                        uploadCompleted = false
                    }
                    if interiorView != nil {
                        var consecutivizedIndex = 0
                        let orderedAssets = getViewAssets(view: interiorView!).sorted(by: { (a1, a2) -> Bool in
                            return a1.index!.intValue < a2.index!.intValue
                        })
                        for asset in orderedAssets {
                            if consecutivizedIndex == index {
                                uploadCompleted = uploadCompleted && etag == asset.etag
                            }
                            consecutivizedIndex += 1
                        }
                    }
                } else if s3Path.contains("/ec/") {
                    index = getIndex(s3Path: s3Path, separator: "/0-")
                    if let exteriorView = self.getViewOfType(viewType: ExteriorViewMO.self) {
                        for asset in exteriorView.assets ?? [] {
                            if asset.index?.intValue == index {
                                uploadCompleted = uploadCompleted && etag == asset.etag
                            }
                        }
                    } else {
                        uploadCompleted = false
                    }
                } else if s3Path.contains("cu-") {
                    index = getIndex(s3Path: s3Path, separator: "cu-")
                    // Get the indexth asset and compare asset. Check closeup and misc view.
                    let closeupView = self.getViewOfType(viewType: CloseupViewMO.self)
                    var found = false
                    for view in [closeupView] {
                        if let view = view {
                            var consecutivizedIndex = 0
                            let assets = getViewAssets(view: view)
                            let orderedAssets = assets.sorted(by: { (a1, a2) -> Bool in
                                if let index1 = a1.index, let index2 = a2.index {
                                    return index1.intValue < index2.intValue
                                }
                                return false
                            })
                            for asset in orderedAssets {
                                if consecutivizedIndex == index {
                                    found = true
                                    uploadCompleted = uploadCompleted && etag == asset.etag
                                }
                                consecutivizedIndex += 1
                            }
                        }
                    }
                    uploadCompleted = uploadCompleted && found // Gone through both closeups and miscs and found nothing.
                } else if s3Path.contains("/pano/") {
                    let interiorView = self.getViewOfType(viewType: InteriorViewMO.self)
                    if interiorView != nil && interiorView?.pano != 1 {
                        uploadCompleted = false
                    }
                    if let assets = interiorView?.assets {
                        if assets.count > 0 {
                            uploadCompleted = uploadCompleted && etag == assets[0].etag
                        } else {
                            uploadCompleted = false
                        }
                    }
                }
            }
        }
        inconsistentUpload = totalChecked > length
        uploadCompleted = totalChecked >= length
        built = info["built"] as? Bool ?? false

        return [
            "uploadComplete": uploadCompleted,
            "built": built,
            "inconsistentUpload": inconsistentUpload,
        ]
    }
    
    func setUploadState(attributes: [String: Any]) -> UploadState {
        let uploadComplete = (attributes["uploadComplete"] as? Bool) ?? false
        let built = (attributes["built"] as? Bool) ?? false
        let inconsistentUpload = (attributes["inconsistentUpload"] as? Bool) ?? false
        let defective =  (attributes["defective"] as? Bool) ?? false

        return setUploadState(uploadComplete: uploadComplete, built: built, inconsistentUpload: inconsistentUpload, defective: defective)
    }

    func setUploadState(uploadComplete: Bool, built: Bool, inconsistentUpload: Bool, defective: Bool = false) -> UploadState {
        if defective {
            self.status = .Defective
        } else {
            if uploadComplete {
                self.status = .UploadComplete
                if let spin = self as? SpinMO, built {
                    self.status = .Built
                }
            } else {
                self.status = .None
            }
            if inconsistentUpload {
                self.status = .Inconsistent
            }
        }
        return self.status
    }

    func verifyFiles () -> [String: String] {  // Misleading name
        var ret: [String: String] = [:]
        if let views = self.views {
            for view in views {
                if let assets = view.assets {
                    for asset in assets {
                        if !asset.fileExists() {
                            var identifier = ""
                            if let fullURL = asset.fullURL?.path {
                                if fullURL.contains("/video/") {
                                    identifier = "video"
                                }
                                if fullURL.contains("/pano/") {
                                    identifier = "pano"
                                }
                            }
                            // Get correct interior
                            // Get misc with no tag
                            if identifier == "" {
                                if let tag = asset.tag, tag != "" {
                                    identifier = tag
                                }
                                if let index = asset.index?.intValue {
                                    if view is InteriorViewMO {
                                        identifier = "Interior \(index)"
                                    } else if view is ExteriorViewMO && identifier == "" {
                                        identifier = "Exterior \(index)"
                                    }
                                }
                            }
                            ret[identifier] = asset.fullURL?.path
                        }
                    }
                }
            }
        }
        return ret
    }
    
    func reset() {
        // Reset the value of uploaded in all assets of all views
        // Allow reuploads to occur
        if let views = self.views {
            for view in views {
                view.reset()
            }
        }
    }
    
    func createEvent(ofType: EventType, forDate: Date = Date()) {
        guard let newEvent = NSEntityDescription.insertNewObject(forEntityName: "Event", into: DataController.sharedInstance.managedObjectContext) as? EventMO,
        let spin = self as? SpinMO else {
            return
        }
        newEvent.setValue(self, forKey: "spin")
        newEvent.setValue(forDate, forKey: "date")
        newEvent.setValue(ofType.rawValue, forKey: "type")
        spin.events?.insert(newEvent)
    }
    
    func getLastEventOf(type: EventType) -> EventMO? {
        guard let spin = self as? SpinMO else { return nil }
        if let events = spin.events?.filter( { return $0.type == type.rawValue } ) {
            let sortedEvents = events.sorted(by: {
                if let firstDate = $0.date,
                let secondDate = $1.date {
                    return firstDate.compare(secondDate as Date) == .orderedDescending
                }
                return false
            })
            return sortedEvents.first
        }
        return nil
    }
    
}

