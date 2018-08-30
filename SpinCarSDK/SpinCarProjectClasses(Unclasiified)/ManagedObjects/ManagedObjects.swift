//
//  AssetMO.swift
//  SpinCar
//

import CoreData
import UIKit


class SaveableMO: NSManagedObject {
    @NSManaged var id: String?
    @NSManaged var state: String? // Raw value of .status property
    @NSManaged var type: String?
    @NSManaged var views: [ViewMO]?
    @NSManaged var accountID: String? // Property only used with lot service users
    var uploading = false
}

class SpinMO: SaveableMO {
    @NSManaged var events: Set<EventMO>?
}

class VideoMO: SaveableMO {
    @NSManaged var isMisc: NSNumber?
    @NSManaged var isHotspot: NSNumber?
}

class EventMO: NSManagedObject {
    @NSManaged var type: String?
    @NSManaged var date: NSDate?
}

class ViewMO: NSManagedObject {
    @NSManaged var saveable: SaveableMO?
    @NSManaged var assets: [AssetMO]?
    
    var relativeOrder: Int {
        return -1
    }
    
    var assetCount: Int? {
        get {
            return self.assets?.count
        }
    }
}

class ExteriorViewMO: ViewMO {
    @NSManaged var exteriorType: String?
    override var relativeOrder: Int {
        return 4
    }
}

class ImageViewMO: ViewMO {
    override var relativeOrder: Int {
        return 3
    }
}

class HotspotViewMO: ImageViewMO {
    override var relativeOrder: Int {
        return 5
    }
}

class InteriorViewMO: ImageViewMO {
    @NSManaged var pano: NSNumber?
    override var relativeOrder: Int {
        return 0
    }
}

class AssetMO: NSManagedObject {
    @NSManaged var view: ViewMO?
    @NSManaged var filePath: String?
    @NSManaged var etag: String?
    @NSManaged var index: NSNumber?
    @NSManaged var tag: String?
    @NSManaged var thumbnailPath: String?
    @NSManaged var uploaded: NSNumber? // Actually boolean, and the Swift type "boolean" doesn't actually exist in obj-c; Booleans are just a fancy one bit number aren't they?
}

class CloseupViewMO: ImageViewMO {
    @NSManaged var closeupAssets: Set<CloseupAssetMO>?
    
    override var relativeOrder: Int {
        return 2
    }
    
    override var assets: [AssetMO]? {
        set {}
        get {
            return Array(self.closeupAssets ?? Set())
        }
    }
    
    override var assetCount: Int? {
        get {
            return self.closeupAssets?.count
        }
    }
}
