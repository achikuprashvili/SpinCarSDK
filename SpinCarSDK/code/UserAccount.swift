//
//  UserAccount.swift
//  SpinCarSDK
//
//  Created by Archil Kuprashvili on 8/28/18.
//

import Foundation
open class UserAccount: SDKResult{
    private var email: String!
    private var password: String!
    private var token: String!
    private var tokenUpdateTime: Date!
    private var serviceCustomerDictionary: [String: ServiceCustomer] = [:]
    private var shootWalkaround: Bool!
    
    
    public func getEmail() -> String{
        return email
    }
    
    public func getPassword() -> String{
        return password
    }
    
    public func getToken() -> String{
        return token
    }
    
    public func getTokenUpdateTime() -> Date{
        return tokenUpdateTime
    }
    
    public func getServiceCustomerMapImmutable() -> NSDictionary{
        return NSDictionary(dictionary: serviceCustomerDictionary)
    }
    public func getServiceCustomerMap() -> NSMutableDictionary{
        return NSMutableDictionary(dictionary: serviceCustomerDictionary)
    }
    
    public func canShootWalkaround() -> Bool{
        return shootWalkaround
    }
    
    public func isMultyUser() -> Bool{
        return !serviceCustomerDictionary.isEmpty
    }
    
    override init() {
        super.init()
    }
    
    func setEmail(email: String){
        self.email = email
    }
    
    func setPassword(password: String){
        self.password = password
    }
    
    func setToken(token: String){
        self.token = token
    }
    
    func setTokenUpdateTime(tokenUpdateTime: Date){
        self.tokenUpdateTime = tokenUpdateTime
    }
    
    func setShootWalkaround(shootWalkaround: Bool) {
        self.shootWalkaround = shootWalkaround
    }
    
    
}
