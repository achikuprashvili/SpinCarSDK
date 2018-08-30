//
//  ViewMO.swift
//  SpinCar
//
//  Copyright © 2016 SpinCar. All rights reserved.
//

import Foundation

func > (left: ViewMO, right: ViewMO) -> Bool {    
    if left.assetCount == 0 || right.assetCount == 0 {
        return right.assetCount == 0
    }
    return left.relativeOrder > right.relativeOrder
}

extension ViewMO {
    override func willSave() {
        super.willSave()
        self.saveable?.willSave()
    }
    
    @objc var fullURL: NSURL? {
        get {
            return self.saveable?.getDirectory()
        }
    }
}

extension ViewMO {
    func reset() {
        if let assets = self.assets {
            for asset in assets {
                asset.uploaded = 0
            }
        }
    }
}

extension ExteriorViewMO {
    override var fullURL: NSURL? {
        get {
            if self.exteriorType == "video" {
                return super.fullURL?.appendingPathComponent("video") as NSURL?
            } else {
                return super.fullURL?.appendingPathComponent("img/ec") as NSURL?
            }
        }
    }
}

extension ImageViewMO {
    override var fullURL: NSURL? {
        get {
            return super.fullURL?.appendingPathComponent("img") as NSURL?
        }
    }
}

extension CloseupViewMO {
    override var fullURL: NSURL? {
        get {
            return super.fullURL?.appendingPathComponent("closeups") as NSURL?
        }
    }
}

extension HotspotViewMO {
    override var fullURL: NSURL? {
        get {
            return super.fullURL?.appendingPathComponent("closeups") as NSURL?
        }
    }
}

extension InteriorViewMO {
    var panoPath: NSURL? {
        get {
            return super.fullURL?.appendingPathComponent("pano") as NSURL?
        }
    }

    var interiorPath: NSURL? {
        get {
            return super.fullURL?.appendingPathComponent("i") as NSURL?
        }
    }

    override var fullURL: NSURL? {
        get {
            let directory = self.pano == 1 ? "pano" : "i"
            return super.fullURL?.appendingPathComponent(directory) as NSURL?
        }
    }
}
