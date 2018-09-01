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
    private var customerId: String!{
        didSet{
            self.spinMo?.accountID = customerId
        }
    }
    private var timestamp: Date!
    private var status: Status = .INVALID
    private var assetsMap:  [AssetType : [Asset]] = [:]
    
//    project savable modesls
    private var spinMo: SpinMO?
    private var exteriorMo: ExteriorViewMO?
    
    
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
        self.initSpinMo()
        
    }
    

    private func initSpinMo(){
        guard let spin = self.dc.newEntity(entityName: "Spin") as? SpinMO else {
            fatalError("cannot create spin entity")
            return
        }
        
        spinMo = spin
        spinMo?.setValue(self.vinStock, forKey: "id")
        spinMo?.setValue("", forKey: "type")
        spinMo?.status = .Built
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
        assetsMap[.EXTERIOR] = []
        assetsMap[.INTERIOR] = []
    }
    
    open func clearAssetsFor(type: AssetType){
        assetsMap[type] = []
    }
    
    open func removeAssetForTypeAndIndex(type: AssetType, index: Int){
        assetsMap[type]?.remove(at: index)
    }
    
    open func addAssetFor(type: AssetType, asset: Asset){
        assetsMap[type]?.append(asset)
    }
    
    open func addAssetsFor(type: AssetType, assets: [Asset]){
        assetsMap[type]?.append(contentsOf: assets)
    }
    
    func setVinStock(vinStock: String){
        self.vinStock = vinStock
    }
    
    func setCustomerId(customerId: String){
        self.customerId = customerId
    }
    
    func setStatus(status: Status){
        self.status = status
    }
    
    func setTimestamp(timestamp: Date){
        self.timestamp = timestamp
    }
}




