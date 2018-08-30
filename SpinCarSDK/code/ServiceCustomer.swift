//
//  ServiceCustomer.swift
//  SpinCarSDK
//
//  Created by Archil Kuprashvili on 8/28/18.
//

import Foundation
final class ServiceCustomer{
    private var id:String!
    private var name:String!
    
    public func getId() -> String{
        return id
    }
    
    public func getName() -> String{
        return name
    }
    
    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
    
    func setName(name: String) -> ServiceCustomer {
        self.name = name
        return self
    }
    
    func setId(id: String) -> ServiceCustomer {
        return self
    }
    
}
