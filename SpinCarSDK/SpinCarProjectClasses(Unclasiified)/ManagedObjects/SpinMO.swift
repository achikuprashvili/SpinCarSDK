//
//  SpinMO.swift
//  SpinCar
//
//  Copyright © 2016 SpinCar. All rights reserved.
//

import Foundation

struct Point {
    var x: CGFloat = 0
    var y: CGFloat = 0
    
    init(xPos: CGFloat, yPos: CGFloat) {
        x = xPos
        y = yPos
    }
    
    init(string: String) {
        x = Double(string.components(separatedBy: ",")[0]).map{ CGFloat($0) }!
        y = Double(string.components(separatedBy: ",")[1]).map{ CGFloat($0) }!
    }
    
    func stringVersion() -> String {
        return "\(x),\(y)"
    }
}

struct Closeup {
    var closeup: Int?
    var name: String = ""
    var icon: String?
    var door: Bool?
    var image: UIImage?
    var isHotspot: Bool?
    // Three types of coords
    // Note: we don't do anything with these but we may in the future -- WW 1/2017
    var i: [String: AnyObject]?
    var ec: [String: AnyObject]?
    var pano: [String: AnyObject]?
    
    init (name: String, closeup: Int) {
        self.name = name
        self.closeup = closeup
        self.icon = "default"
    }
    
    init (closeup: Int?, name: String?, icon: String?, door: Bool?, i: [String: AnyObject]?, ec: [String: AnyObject]?, pano: [String: AnyObject]?, isHotspot: Bool? = false) {
        self.closeup = closeup
        self.name = name ?? ""
        self.icon = icon
        self.door = door
        self.i = i
        self.ec = ec
        self.pano = pano
        self.isHotspot = isHotspot
    }
    
    // Key corresponds to photo coordinates are on
    var positions: [Int: Point] = [:]
    var buttons: [Int: UIButton] = [:]
    
    init(still: UIImage?, hotspotName: String) {
        self.image = still
        name = hotspotName
    }
    
    mutating func updatePositions() {
        for button in self.buttons {
            // Have to convert button coords back to backend system
            let point = Point(xPos: button.1.frame.origin.x/UIScreen.main.bounds.width, yPos: button.1.frame.origin.y/UIScreen.main.bounds.height)
            self.positions[button.0] = point
        }
    }
    
    func convertToAppCoordinates() -> [Int: Point]? {
        var nativeCoords: [Int: Point] = [:]
        for position in self.positions {
            // Convert backend point -> native point here
            let point = position.value
            // Don't convert coords that are already converted
            if point.x > 2 {
                continue
            }
            let coordinate = Point(xPos: point.x * UIScreen.main.bounds.width, yPos: point.y * UIScreen.main.bounds.height)
            nativeCoords[position.0] = coordinate
        }
        return nativeCoords
    }
}

func ==(left: [Closeup]?, right: [Closeup]?) -> Bool {
    // Assumes both lists are sorted similarly.
    guard let lhs = left else {
        return left == nil && right == nil
    }
    guard let rhs = right else {
        return false
    }
    if lhs.count != rhs.count {
        return false
    }
    var equality = true
    for (i, left) in lhs.enumerated() {
        let right = rhs[i]
        equality = equality && left == right
    }
    return equality
}

func !=(left: [Closeup]?, right: [Closeup]?) -> Bool {
    return !(left == right)
}

func ==(lhs: Closeup, rhs: Closeup) -> Bool {
    // This only checks name and closeup, since these are the only attributes
    // that this app changes.
    // In the future this will have to become more robust.
    var equality = true
    equality = equality && lhs.name == rhs.name
    equality = equality && lhs.closeup == rhs.closeup
    return equality
}

extension SpinMO {
    
    var closeupsComplete: Bool {
        if let closeupAssets = self.getViewOfType(viewType: CloseupViewMO.self)?.assets {
            if self.closeUpTags?.count == 0 {
                return closeupAssets.count == 1
            }
            // Compare this to the default closeup list
            if closeupAssets.count != self.defaultCloseups.count {
                return false
            }
            return true
        }
        return false
    }
    
    var interiorsComplete: Bool {
        if let interiorView = self.getViewOfType(viewType: InteriorViewMO.self) {
            if interiorView.pano == 1 && interiorView.assetCount == 1 {
                return true
            }
            if interiorView.pano == 0 && interiorView.assetCount == 8 {
                return true
            }
        }
        return false
    }
    
    var exteriorsComplete: Bool {
        if let exteriorViewAssets = (self.getViewOfType(viewType: ExteriorViewMO.self))?.assets {
            return exteriorViewAssets.count != 0
        } else {
            return false
        }
    }
    
    var isComplete: Bool {
        return self.exteriorsComplete && self.closeupsComplete && self.interiorsComplete
    }
    
    var closeUpTags: [Int: String]? {
        set {}
        get {
            var tags: [Int: String]?
            if let closeupView = self.getViewOfType(viewType: CloseupViewMO.self),
            let closeups = closeupView.closeupAssets {
                tags = [:]
                for closeup in closeups {
                    tags![Int(closeup.index!)] = closeup.tag
                }
            }
            return tags
        }
    }
    
    var miscTags: [String]? {
        set {}
        get {
            var tags: [String]?
            if let closeupView = self.getViewOfType(viewType: CloseupViewMO.self),
                let closeupAssets = closeupView.closeupAssets {
                tags = []
                for asset in closeupAssets {
                    if (asset.isMisc ?? 0) == 1 {
                        tags?.append(asset.tag ?? "No Tag")
                    }
                }
            }
            return tags
        }
    }
    
    var exteriorPhotoURLs: [Int: String]? {
        set {}
        get {
            return getPhotoURLs(for: ExteriorViewMO.self)
        }
    }
    
    var interiorPhotoURLs: [Int: String]? {
        return getPhotoURLs(for: InteriorViewMO.self)
    }
    
    var closeUpsPhotoURLs: [Int: String]? {
        set {}
        get {
            return getPhotoURLs(for: CloseupViewMO.self)
        }
    }
    
    var taggedHotspots: [String: AnyObject] {
        set {}
        get {
            return [String: AnyObject]()
        }
    }
    
    var defaultHotspots: String {
        set {}
        get {
            guard let hotspotString = UserDefaults.standard.string(forKey: "hotspots") else {
             return "[{\"closeup\":0,\"ec\":{\"0\":[0.2075,0.5466666666666666],\"7\":[0.54,0.8133333333333334],\"num_interpolating\":8},\"icon\":\"default\",\"name\":\"Wheel\"},{\"closeup\":1,\"ec\":{\"1\":[0.87,0.5033333333333333],\"2\":[0.4875,0.54],\"3\":[0.155,0.63],\"num_interpolating\":8},\"icon\":\"trunk\",\"name\":\"Trunk\"},{\"closeup\":2,\"ec\":{\"5\":[0.8925,0.6],\"6\":[0.495,0.44333333333333336],\"7\":[0.1675,0.58],\"num_interpolating\":8},\"icon\":\"default\",\"name\":\"Engine\"},{\"door\":true,\"ec\":{\"0\":[0.535,0.44],\"1\":[0.38,0.4533333333333333],\"3\":[0.7525,0.5266666666666666],\"4\":[0.4375,0.55],\"5\":[0.21,0.5333333333333333],\"7\":[0.8125,0.5266666666666666],\"num_interpolating\":8}},{\"closeup\":3,\"i\":{\"0\":[0.3325,0.3566666666666667],\"7\":[0.53,0.20666666666666667],\"num_interpolating\":8},\"icon\":\"mileage\",\"name\":\"Mileage\"},{\"closeup\":4,\"i\":{\"0\":[0.7125,0.41],\"7\":[0.8525,0.4866666666666667],\"num_interpolating\":8},\"icon\":\"default\",\"name\":\"Audio\"}]"
            }
            return hotspotString
        }
    }
    
    var defaultCloseups: [String] {
        // Use defaultHotspotString and the NSUserDefault for hotspot string to generate a list of closeups
        // to display on the "CloseupsView"
        // Not a source of truth.
        
        get {
            var closeupNames: [String] = []
            for hotspot in self.convertHotspotString(jsonString: defaultHotspots, ignoreDoor: true) {
                closeupNames.append(hotspot.name.uppercased())
            }
            // Another special case.
            let srp = NSLocalizedString(
                "SRP",
                comment: "The search results page photo of a car"
            )
            closeupNames.insert(srp, at: 0)
            return closeupNames
        }
    }
    
    var closeups: [Closeup]? {
        get {
            let closeupView = self.getViewOfType(viewType: CloseupViewMO.self)
            var hotspots = self.convertHotspotString(jsonString: self.defaultHotspots, ignoreDoor: false)
            // Need to be ordered because the array will be in the order in which they were shot
            let orderedCloseups: [CloseupAssetMO] = closeupView?.closeupAssets?.sorted(by: { return $0.index?.intValue ?? 0 < $1.index?.intValue ?? 0 } ) ?? []
            var assetNames: [String] = []
            var consecutivizedIndex = 0
            for closeup in orderedCloseups {
                guard let tag = closeup.tag else {
                    break
                }
                // If the asset is the "SRP" photo, it does not impact the hotspots
                if tag == Constants.srpString {
                    consecutivizedIndex += 1
                    continue
                }
                assetNames.append(tag.uppercased())
                var mutableHotspot: Closeup?
                var index: Int?
                var shouldRemoveCloseup = true
                for (i, hotspot) in (hotspots.enumerated()) {
                    index = i
                    if hotspot.name.uppercased() == tag.uppercased() {
                        mutableHotspot = hotspot
                        shouldRemoveCloseup = false
                        break
                    }
                }
                if index != nil && mutableHotspot != nil {
                    mutableHotspot!.closeup = consecutivizedIndex
                    if shouldRemoveCloseup {
                        mutableHotspot!.closeup = nil
                    }
                    hotspots[index!] = mutableHotspot!
                }
                
                if let misc = closeup.isMisc,
                misc == 1 {
                    hotspots.append(
                        Closeup(
                            closeup: consecutivizedIndex,
                            name: tag,
                            icon: nil,
                            door: nil,
                            i: nil,
                            ec: nil,
                            pano: nil,
                            isHotspot: false
                        )
                    )
                }
                consecutivizedIndex += 1
            }
            // Get rid of "closeup" keys for closeups that were not taken
            for (i, hotspot) in hotspots.enumerated() {
                if !assetNames.contains(hotspot.name.uppercased()) {
                    hotspots[i].closeup = nil
                }
            }
            return hotspots.sorted(by: { return $0.closeup ?? hotspots.count < $1.closeup ?? hotspots.count})
        }
    }
    
    var closeupsWithHotspots: [String] {
        get {
            var hotspots: [String] = []
            for hotspot in self.convertHotspotString(jsonString: defaultHotspots, ignoreDoor: true) {
                if hotspot.isHotspot ?? false {
                    hotspots.append(hotspot.name.uppercased())
                }
            }
            return hotspots
        }
    }
    
    override public func willSave() {
        super.willSave()
        // Save JSON data for desktop uploads if we have shot assets
        if !self.isEmpty() {
            self.saveJSONData()
        }
    }
    
    func saveJSONData() {
        let _ = SaveableFileManager(spin: self)
    }
    
    // MARK: - Helper Functions

    fileprivate func getPhotoURLs<T>(for type: T.Type) -> [Int: String]? {
        var photoURLs: [Int: String]? = [:]
        let view = self.getViewOfType(viewType: type) as? ViewMO
        if let assets = view?.assets {
            for asset in assets {
                if asset.fullURL?.pathExtension == "mov" {
                    continue
                }
                photoURLs![Int(asset.index!)] = asset.filePath
            }
        }
        return photoURLs
    }
    
    fileprivate func getTags<T>(for type: T.Type) -> [Int: String]? {
        var tags: [Int: String]?
        if let view = self.getViewOfType(viewType: type) as? ViewMO,
            let views = view.assets {
            tags = [Int: String]()
            for misc in views {
                tags![Int(misc.tag!)!] = misc.fullURL?.path!
            }
        }
        return tags
    }

    func convertHotspotDataToString(hotspotArray hotspots: [Closeup]) -> NSString {
        var hotspotsAsObject: [[String: AnyObject]] = []
        // When we set hotspots, update the hotspot string.
        for hotspotObject in hotspots {
            let closeup = hotspotObject.closeup ?? -1
            let icon = hotspotObject.icon ?? ""
            let name = hotspotObject.name 
            let door = hotspotObject.door ?? false

            let i = hotspotObject.i ?? [:]
            let ec = hotspotObject.ec ?? [:]
            let pano = hotspotObject.pano ?? [:]
            var newHotspot: [String: AnyObject] = [
                "name": name as AnyObject,
                "closeup": closeup as AnyObject,
                "icon": icon as AnyObject
            ]
            if closeup == -1 {
                newHotspot.removeValue(forKey: "closeup")
            }
            // This isn't important, since an empty set of coordinates for a view is the same as being coordinateless in that view
            // But it makes testing easier. Same logic applies to door.
            if i.count > 0 {
                newHotspot["i"] = i as AnyObject?
            }
            if ec.count > 0 {
                newHotspot["ec"] = ec as AnyObject?
            }
            if pano.count > 0 {
                newHotspot["pano"] = pano as AnyObject?
            }
            if door {
                newHotspot["door"] = true as AnyObject?
            }
            hotspotsAsObject.append(newHotspot)
        }
        
        return self.convertHotspotDataToString(hotspotsAsObject)
    }

    func convertHotspotDataToString(_ newHotspots: [[String: AnyObject]]) -> NSString {
        var editedHotspotData: NSData!
        do {
            editedHotspotData = try JSONSerialization.data(withJSONObject: newHotspots, options: JSONSerialization.WritingOptions(rawValue: 0)) as NSData?
        } catch let error as NSError {
            SpinCarCrashlyticsLogger.SpinCarLogger.log("Error created hotspot data %@", varargs: [error])
        }

        return NSString(data: editedHotspotData as Data, encoding: String.Encoding.utf8.rawValue)!
    }

    func convertHotspotString(jsonString: String, ignoreDoor: Bool) -> [Closeup] {
        var closeups: [Closeup] = []

        if let hotspotJSON = CommonHelpers.CommonHelper.convertStringToJSON(jsonString) as? [[String: AnyObject]] {
            var index = 1
            for hotspotObject in hotspotJSON {
                var closeup: Int?
                let icon = hotspotObject["icon"] as? String
                let name = hotspotObject["name"] as? String
                let door = hotspotObject["door"] as? Bool
                
                let i = hotspotObject["i"] as? [String: AnyObject] ?? [:]
                let ec = hotspotObject["ec"] as? [String: AnyObject] ?? [:]
                let pano = hotspotObject["pano"] as? [String: AnyObject] ?? [:]
                let hotspot = !i.isEmpty || !ec.isEmpty || !pano.isEmpty
                
                if (hotspotObject["closeup"] as? Int) != nil {
                    closeup = index
                    index += 1
                }
                
                if ignoreDoor && door == true {
                    continue
                }
                if hotspot {
                    let newHotspot = Closeup(
                        closeup: closeup,
                        name: name,
                        icon: icon,
                        door: door,
                        i: i,
                        ec: ec,
                        pano: pano,
                        isHotspot: true
                    )
                    closeups.append(newHotspot)
                } else {
                    let newHotspot = Closeup(
                        closeup: closeup,
                        name: name,
                        icon: icon,
                        door: door,
                        i: i,
                        ec: ec,
                        pano: pano
                    )
                    closeups.append(newHotspot)
                }
            }
        }
        return closeups
    }

    func mergeNewDefaultHotspots(oldHotspotString: String, newHotspotString: String) -> [String] {
        // Merges the old default hotspot string with the new one received by the API earlier.
        // Sets the value of "defaultHotspots" attribute and returns the list of default closeups
        let newHotspots = self.convertHotspotString(jsonString: newHotspotString, ignoreDoor: true)
        let oldHotspots = self.convertHotspotString(jsonString: oldHotspotString, ignoreDoor: true)
        var mutatedCloseups: [Closeup] = oldHotspots
        var addToEnd: [Closeup] = []
        for newHotspot in newHotspots {
            let oldHotspotIndex = mutatedCloseups.index(where: {$0.name == newHotspot.name})
            if oldHotspotIndex == nil {
                addToEnd.append(newHotspot)
                continue
            }
            var oldHotspot = mutatedCloseups[oldHotspotIndex!]
            // Update closeup, coords, any other values.
            oldHotspot.closeup = newHotspot.closeup
            oldHotspot.ec = newHotspot.ec
            oldHotspot.i = newHotspot.i
            oldHotspot.pano = newHotspot.pano
            oldHotspot.door = newHotspot.door
            oldHotspot.icon = newHotspot.icon
            mutatedCloseups[oldHotspotIndex!] = oldHotspot
        }
        mutatedCloseups += addToEnd
        self.setValue(self.convertHotspotDataToString(hotspotArray: mutatedCloseups), forKey: "defaultHotspots")
        return mutatedCloseups.filter({$0.name != ""}).map({$0.name})
    }
    
    func isEmpty() -> Bool {
        let interiorView = (self.getViewOfType(viewType: InteriorViewMO.self))
        let hasInteriors = interiorView != nil ? (interiorView!.assetCount ?? 0) > 0 : false
        
        let closeupView = self.getViewOfType(viewType: CloseupViewMO.self)
        let hasCloseups = closeupView != nil ? (closeupView!.assetCount ?? 0) > 0 : false
        
        let exteriorView = self.getViewOfType(viewType: ExteriorViewMO.self)
        let hasExteriors = exteriorView != nil ? (exteriorView!.assetCount ?? 0) > 0 : false

        return !(hasExteriors || hasInteriors || hasCloseups)
    }
    
}

extension Dictionary where Value: Equatable {
    func keysForValue(value: Value) -> [Key] {
        return compactMap { (key: Key, val: Value) -> Key? in
            value == val ? key : nil
        }
    }
}
