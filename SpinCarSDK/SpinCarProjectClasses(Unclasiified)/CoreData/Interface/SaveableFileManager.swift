//
//  SaveableFileManager.swift
//  SpinCar
//

import CoreData
import Foundation
import UIKit

class SaveableFileManager {
    let crashlyticslogger = SpinCarCrashlyticsLogger.SpinCarLogger
    let spin: SpinMO?
    let expectedViewFiles = ["video.json", "closeups.json", "i.json", "ec.json", "pano.json"]
    
    // Currently only used for spins
    // If we ever extend this functionality to videos, we can add another initializer that takes a VideoMO
    init(spin: SpinMO) {
        self.spin = spin
        self.saveHotspotData()
        self.saveSettings()
        var array: [AnyObject] = []
        var filePath = ""
        var orderedAssets: [AssetMO] = []
        var closeupViewAssets: [AssetMO]?
        var miscViewAssets: [AssetMO]?
        
        var createdFiles: [String] = []
        
        for view in self.spin!.views ?? [] {
            if let view = view as? CloseupViewMO {
                closeupViewAssets = view.closeupAssets?.sorted(by: { (a1, a2) -> Bool in
                    return a1.index!.intValue < a2.index!.intValue
                }).filter( { return $0.isMisc == 0 } )
                miscViewAssets = view.closeupAssets?.sorted(by: { (a1, a2) -> Bool in
                    return a1.index!.intValue < a2.index!.intValue
                }).filter( { $0.isMisc == 1 } )
                continue
            }
            
            let assets: [AssetMO] = view.assets!.sorted(by: { (a1, a2) -> Bool in
                return a1.index!.intValue < a2.index!.intValue
            })
            
            if let exteriorView = view as? ExteriorViewMO {
                if exteriorView.exteriorType == "video" {
                    filePath = "video.json"
                } else {
                    filePath = "ec.json"
                }
            }
            if let interiorView = view as? InteriorViewMO {
                if interiorView.pano == 1 {
                    filePath = "pano.json"
                } else {
                    filePath = "i.json"
                }
            }
            
            self.processAssetsForJSON(assets: assets, array: &array)
            let url = self.spin?.getDirectory().appendingPathComponent(filePath)
            self.saveJSONData(filePath: url! as NSURL, jsonObject: array as AnyObject)
            createdFiles.append(filePath)
            
            // Clear array
            array.removeAll()
        }
        
        // Save closeups for last because they are generated from two separate views (MiscViewMO & CloseupViewMO)
        filePath = "closeups.json"
        
        if let closeupAssets = closeupViewAssets {
            for name in (self.spin?.defaultCloseups)! {
                for asset in closeupAssets {
                    if let tag = asset.tag {
                        if name == tag {
                            // Add this to ordered closeups
                            orderedAssets.append(asset)
                            break
                        }
                    }
                }
            }
        }
        if let miscAssets = miscViewAssets {
            for asset in miscAssets {
                orderedAssets.append(asset)
            }
        }
        
        self.processAssetsForJSON(assets: orderedAssets, array: &array)
        let url = self.spin?.getDirectory().appendingPathComponent(filePath)
        self.saveJSONData(filePath: url! as NSURL, jsonObject: array as AnyObject)
        createdFiles.append(filePath)
        
        
        // Create empty JSON files for views that were not shot
        for file in self.expectedViewFiles {
            if !createdFiles.contains(file) {
                let url = self.spin?.getDirectory().appendingPathComponent(file)
                self.saveJSONData(filePath: url! as NSURL, jsonObject: [] as AnyObject)
            }
        }
    }
    
    func processAssetsForJSON(assets: [AssetMO], array: inout [AnyObject]) {
        for asset in assets {
            if let fileName = asset.filePath {
                var entry = ["filename": fileName]
                if let tag = asset.tag {
                    if tag != "" {
                        entry["tag"] = tag
                    }
                }
                if let etag = asset.etag {
                    entry["etag"] = etag
                }
                array.append(entry as AnyObject)
            }
        }
    }
    
    func getHotspotData(ignoreDoor: Bool = true) -> Data {
        // Convert the edited JSON to a valid form so Alamofire doesn't complain when we try to upload it
        var editedHotspotData: Data!
        if let closeups = self.spin?.closeups {
            do {
                let editedHotspotString = self.spin?.convertHotspotDataToString(hotspotArray: closeups)
                if let data = editedHotspotString?.data(using: String.Encoding.utf8.rawValue) {
                    do {
                        let editedHotspotJSON = try JSONSerialization.jsonObject(with: data, options: [])
                        editedHotspotData = try JSONSerialization.data(withJSONObject: editedHotspotJSON, options: JSONSerialization.WritingOptions(rawValue: 0))
                    } catch let error as NSError {
                        self.crashlyticslogger.log("Unable to create json object from hotspot string. Reason: %@", varargs: [error.localizedDescription as AnyObject])
                    }
                }
            }
        }
        
        return editedHotspotData
    }
    
    func saveHotspotData() {
        // Edit hotspot string depending on which closeups were taken
        let editedHotspotJSON = self.getHotspotData(ignoreDoor: false)
        
        let filePath = self.spin?.getDirectory().appendingPathComponent("hotspots.json")
        do {
            try editedHotspotJSON.write(to: filePath!, options: .atomicWrite)
        } catch let error as NSError {
            crashlyticslogger.log_non_fatal("Unable to save hotspot string data. Reasons:", reason: error.localizedDescription as AnyObject)
        }
    }
    
    func saveSettings() {
        var settings: [String: AnyObject] = [:]
        // Get EC configuration if the spin is photo-based. Otherwise, set exterior_media to "video".
        let exterior_media = self.spin?.getViewOfType(viewType: ExteriorViewMO.self)?.exteriorType?.components(separatedBy: "-").first
        var tripod_enabled = false
        
        if let oldSettings = UserDefaults.standard.object(forKey:"settings") as? [String: AnyObject] {
            tripod_enabled = (oldSettings[SettingsConstants.tripodModeEnabled] as? Bool ?? false)!
        }
        
        settings[SettingsConstants.tripodModeEnabled] = tripod_enabled as AnyObject?
        settings["exterior_media"] = exterior_media as AnyObject?
        
        if let url = self.spin?.getDirectory().appendingPathComponent("settings.json") {
            self.saveJSONData(filePath: url as NSURL, jsonObject: settings as AnyObject)
        }
    }
    
    func saveJSONData(filePath: NSURL, jsonObject: AnyObject) {
        var data: NSData!
        do {
            data = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted) as NSData?
        } catch let error as NSError {
            self.crashlyticslogger.log("Unable to serialize JSON data. Reasons: \(error.localizedDescription)")
        }
        do {
            try data.write(to: filePath as URL, options: .atomicWrite)
        } catch let error as NSError {
            self.crashlyticslogger.log_non_fatal("Unable to save data. Reasons:", reason: error.localizedDescription as AnyObject)
        }
    }
}

