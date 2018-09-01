//
//  Spin.swift
//  SpinCarSDK
//
//  Created by Archil Kuprashvili on 8/31/18.
//  Copyright © 2018 Archil Kuprashvili. All rights reserved.
//

import Foundation

public enum Status{
    case MODIFIED
    case UPLOADED
    case PUBLISHED
    case INVALID
}

open class Spin: SDKResult{
    private let dc = DataController.sharedInstance
    var crashlyticsLogger = SpinCarCrashlyticsLogger.SpinCarLogger
    private var vinStock: String!
    private var customerId: String!
    private var timestamp: Date!
    private var status: Status = .INVALID
    private var assetsMap:  [AssetType : [Asset]] = [:]
    
//    project savable modesls
    private var spinMo: SpinMO?
    private var exteriorMo: ExteriorViewMO?
    private var interiorMo: InteriorViewMO?
    private var closeupMo: CloseupViewMO?
    
    
    init(spin: Spin) {
        super.init(result: spin)
        self.vinStock = spin.vinStock
        self.customerId = spin.customerId
        self.timestamp = spin.timestamp
        self.status = spin.status
        self.assetsMap = spin.assetsMap
    }
    
    override init() {
        super.init()
        self.clearAllAssets()
    }
    
    init(vinStock: String){
        super.init()
        self.setVinStock(vinStock: vinStock)
        self.clearAllAssets()
        self.status = .MODIFIED
        self.initSpinMo()
        
    }
    

    private func initSpinMo(){
        guard let spin = self.dc.newEntity(entityName: "Spin") as? SpinMO else {
            self.crashlyticsLogger.log("Unable to create a new spin model in \(self).")
            return
        }
        spinMo = spin
        spinMo?.setValue(self.vinStock, forKey: "id")
        spinMo?.setValue("", forKey: "type")
        spinMo?.status = .Built
        if let customer: ServiceCustomer = AccountManager.shared.getAccount().getSelectedServiceCustomer(){
            spinMo?.accountID = customer.getId()
        }
        
        if let exteriorView = self.spinMo?.getViewOfType(viewType: ExteriorViewMO.self) {
            self.exteriorMo = exteriorView
        } else {
            self.exteriorMo = self.dc.newEntity(entityName: "ExteriorView") as? ExteriorViewMO
            self.exteriorMo?.setValue(self.spinMo, forKey: "saveable")
            
        }
        
        if let interiorView = self.spinMo!.getViewOfType(viewType: InteriorViewMO.self) {
            self.interiorMo = interiorView
        } else {
            self.interiorMo = self.dc.newEntity(entityName: "InteriorView") as? InteriorViewMO
            
            self.interiorMo?.setValue(self.spinMo, forKey: "saveable")
        }
        
        if let closeupView = self.spinMo!.getViewOfType(viewType: CloseupViewMO.self) {
            self.closeupMo = closeupView
        } else {
            self.closeupMo = self.dc.newEntity(entityName: "CloseupView") as? CloseupViewMO
            self.closeupMo?.setValue(self.spinMo, forKey: "saveable")
        }
        timestamp = Date()
        spinMo?.createEvent(ofType: .Created, forDate: timestamp)
    
        dc.saveContext()
        
    }
    open func getVinStock() -> String{
        return vinStock
    }
    
    open func getCustomerId() -> String{
        return customerId
    }
    
    open func getTimestamp() -> Date{
        return timestamp
    }
    
    open func getStatus() -> Status{
        return status
    }
    
    open func getAllAssets() -> [Asset]{
        var assets:[Asset] = []
        for type:AssetType in assetsMap.keys {
            assets.append(contentsOf: assetsMap[type] != nil ? assetsMap[type]! : [])
        }
        return assets
    }
    
    open func getAssetMap() -> [AssetType: [Asset]]{
        return assetsMap
    }
    
    open func getAssetsBy(type: AssetType) -> [Asset]{
        var assets:[Asset] = []
        assets.append(contentsOf: assetsMap[type] != nil ? assetsMap[type]! : [])
        return assets
    }
    
    open func getAssetByTypeAndIndex(type: AssetType, index: Int) -> Asset?{
        let asset: Asset? = assetsMap[type]?[index]
        return asset
    }
    
    open func clearAllAssets(){
        assetsMap = [:]
        assetsMap[.CLOSEUP] = []
        dc.delete(mObjects: closeupMo?.assets ?? [])
        dc.delete(mObjects: Array(closeupMo?.closeupAssets ?? []))
        assetsMap[.EXTERIOR] = []
        dc.delete(mObjects: exteriorMo?.assets ?? [])
        assetsMap[.INTERIOR] = []
        dc.delete(mObjects: interiorMo?.assets ?? [])
        dc.saveContext()
        
    }
    
    open func clearAssetsFor(type: AssetType) -> Bool{
        assetsMap[type] = []
        switch type {
        case .CLOSEUP:
            for cAsset in (closeupMo?.closeupAssets ?? Set()){
                dc.delete(mObjects: [cAsset])
            }
            dc.delete(mObjects: Array(closeupMo?.closeupAssets ?? []))
            dc.delete(mObjects: closeupMo?.assets ?? [])
            
        case .EXTERIOR:
            dc.delete(mObjects: exteriorMo?.assets ?? [])
            
        case .INTERIOR:
            dc.delete(mObjects: interiorMo?.assets ?? [])
        }
        
        return dc.saveContext()
    }
    
    open func removeAssetForTypeAndIndex(type: AssetType, index: Int) -> Bool{
        assetsMap[type]?.remove(at: index)
        switch type {
        case .CLOSEUP:
            if let asset = closeupMo?.assets?[index]{
                for cAsset in (closeupMo?.closeupAssets ?? Set()){
                    if cAsset.tag == asset.tag{
                        dc.delete(mObjects: [cAsset])
                    }
                }
                dc.delete(mObjects: [asset] ?? [])
            }
            
        case .EXTERIOR:
            dc.delete(mObjects: exteriorMo?.assets ?? [])
            
        case .INTERIOR:
            dc.delete(mObjects: interiorMo?.assets ?? [])
            
        }
        return dc.saveContext()
    }
    
    open func addAssetFor(type: AssetType, asset: Asset) -> Bool{
        if !((asset.assetMo?.fileExists())!){
            return false
        }

        
        assetsMap[type]?.append(asset)
        switch type {
        case .CLOSEUP:
            asset.assetMo?.setValue(self.closeupMo, forKey: "closeupView")
            asset.assetMo?.setValue(assetsMap[type]!.count - 1 >= (self.spinMo?.defaultCloseups.count) ?? 0, forKey: "isMisc")
            asset.assetMo?.setValue(asset.isHotspot(), forKey: "isHotspot")
        case .EXTERIOR:
            asset.assetMo?.setValue(self.exteriorMo, forKey: "view")
            exteriorMo?.exteriorType = asset.isVideo() ? "video" : "photo"
        case .INTERIOR:
            asset.assetMo?.setValue(self.interiorMo, forKey: "view")
            interiorMo?.pano = NSNumber(value: asset.isPanoramic())
        }
        spinMo?.status = .None
        return dc.saveContext()
    }
    
    open func addAssetsFor(type: AssetType, assets: [Asset]){
        for asset in assets{
            self.addAssetFor(type: type, asset: asset)
        }
    }
    
    func setVinStock(vinStock: String){
        self.vinStock = vinStock
        self.spinMo?.id = vinStock
    }
    
    open func setCustomerId(customerId: String){
        self.customerId = customerId
        self.spinMo?.accountID = customerId
        
    }
    
    func setStatus(status: Status){
        self.status = status
    }
    
    func setTimestamp(timestamp: Date){
        self.timestamp = timestamp
    }
    
    
    
}




