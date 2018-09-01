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
    private var selectedServiceCustomer: ServiceCustomer?
    
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
    

    
    public func canShootWalkaround() -> Bool{
        return shootWalkaround
    }
    
    public func isMultyUser() -> Bool{
        return serviceCustomerDictionary.count > 1
    }
    
    public func getSelectedServiceCustomer() -> ServiceCustomer? {
        return selectedServiceCustomer
    }
    
    public func selectServiceCustomer(By customerID: String) -> Bool{
        if serviceCustomerDictionary.keys.contains(customerID){
            selectedServiceCustomer = serviceCustomerDictionary[customerID]
            return true
        }
        return false
    }
    override init() {
        super.init()
    }
    
    func addServiceCustomer(serviceCustomer: ServiceCustomer){
        serviceCustomerDictionary[serviceCustomer.getId()] = serviceCustomer
        if selectedServiceCustomer == nil {
            selectedServiceCustomer = serviceCustomer
        }
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
