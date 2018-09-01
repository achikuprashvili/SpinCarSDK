//
//  SpinManager.swift
//  SpinCarSDK
//
//  Created by Archil Kuprashvili on 8/31/18.
//  Copyright © 2018 Archil Kuprashvili. All rights reserved.
//

import Foundation
open class SpinManager{
    private let spinRepository = SpinRepository.shared
    
    private init() {
      
    }
    
    open static let shared = SpinManager()
    
    public func createSpin(vinStock: String) -> Spin{
        let formattedVin = vinStock.replacingOccurrences(of: " ", with: "")
        let result = Spin(vinStock: formattedVin)
        
        if spinRepository.spinExists(vinStock: formattedVin){
            result.setError(error: .SPIN_VIN_DUPLICATE)
            print ("error vin dub")
            
            return result
        }
        
        if !spinRepository.isValidVin(vinStock: formattedVin){
            result.setError(error: .SPIN_VIN_INVALID)
        }
        result.setVinStock(vinStock: formattedVin)
        result.setStatus(status: .MODIFIED)
        result.setTimestamp(timestamp: Date())
        if let customer = AccountManager.shared.getAccount().getSelectedServiceCustomer() as? ServiceCustomer{
            result.setCustomerId(customerId: customer.getId())
        }
        return result
    }
    
    public func loadSpin(vinStock: String) -> Spin{
        
        return Spin(vinStock: "s")
    }
    
    public func loadSpins(VinFilter: String) -> [Spin]{
        return [Spin(vinStock: "s")]
    }
    
    public func removeSpin(vinStock: String, removeMedia: Bool) -> SDKResult{
        return SDKResult().setError(error: .SPIN_REMOVE)
    }
    
    public func renameSpin(vinStock: String, newVinStock: String) -> SDKResult{
        return SDKResult().setError(error: .SPIN_RENAME)
    }
    
    public func setSpinCustomerId(vinStock:String, customerId: String) -> Spin{
        return Spin(vinStock: "s")
    }
    
    public func createAsset(assetType: AssetType, index: Int, mimeType: String, isVideo: Bool, isPanoramic: Bool, isHotspot: Bool, closeupTag: String, mediaPath: String, thumbPath: String) -> Asset{
        return Asset(type: assetType, localPath: mediaPath, thumbPath: thumbPath, etag: "tag", mimeType: mimeType, isVideo: isVideo, isPanoramic: isPanoramic, isHotspot: isHotspot, closeupTag: closeupTag)
    }
    
    public func uploadSpin(){
        
    }
}
