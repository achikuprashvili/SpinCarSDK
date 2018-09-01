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
    
    
}
