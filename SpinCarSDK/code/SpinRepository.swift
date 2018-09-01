//
//  SpinRepository.swift
//  SpinCarSDK
//
//  Created by Archil Kuprashvili on 8/31/18.
//  Copyright © 2018 Archil Kuprashvili. All rights reserved.
//

import Foundation
import CoreData
open class SpinRepository{
    let dc = DataController.sharedInstance
    var spins: [NSManagedObject] = []

    private init() {
        fetchSpins()
        
    }
    
    open static let  shared = SpinRepository()
    private func fetchSpins(){
        spins = self.dc.fetch(entityName: "Saveable")

    }
    
    public func isValidVin(vinStock: String) -> Bool {
        
        let formattedVin = vinStock.replacingOccurrences(of: " ", with: "")
        
        return !(formattedVin.contains("/") || formattedVin.contains("\\") || formattedVin.isEmpty)
    }
    
    public func spinExists(vinStock: String) -> Bool{
        
        let formattedVin = vinStock.replacingOccurrences(of: " ", with: "")
        for managedObject in spins {
            
            if let spin = managedObject as? SpinMO {
                if spin.id == formattedVin{
                    return true
                }
            }
        }
        return false
    }
    
}
