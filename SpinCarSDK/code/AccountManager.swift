//
//  AccountManager.swift
//  SpinCarSDK
//
//  Created by Archil Kuprashvili on 8/28/18.
//

import Foundation
import Alamofire
open class AccountManager {
    let HTTPClient: SpinCarHTTPClient = SpinCarHTTPClient()
    private var userAccount: UserAccount = UserAccount()
    
    open static let shared = AccountManager()
    
    private init(){
        _ = userAccount.setError(error: SDKError.ACCOUNT_LOGIN)
    }
    
    
    public func login(email: String, password: String, completionHandler: @escaping (Bool, UserAccount) -> ()){
        HTTPClient.login(email: email, password: password) { (success, response) in
            if (!success){
                let userAccount: UserAccount = UserAccount()
                _ = userAccount.setError(error: SDKError.ACCOUNT_LOGIN).setMessage(message: "failed to login")

                completionHandler(success, userAccount)
                
            }else{
                
                self.userAccount.setShootWalkaround(shootWalkaround: (response["shoot_walkaround"] as? Bool) ?? true)
                if let token = response["token"] as? String {
                    self.userAccount.setError(error: .NO_ERROR)
                    self.userAccount.setEmail(email: email)
                    self.userAccount.setPassword(password: password)
                    self.userAccount.setToken(token: token)
                    self.userAccount.setTokenUpdateTime(tokenUpdateTime: Date())
                    self.userAccount.setMessage(message: "valid user account")
                    if let lotServiceCustomers = response["lot_service_customers"] as? String {
                        let accounts = lotServiceCustomers.components(separatedBy: ",")
                        for account in accounts {
                            // String will be in format: "userID:nickname"
                            let temp = account.components(separatedBy: ":")
                            if let userID = temp.first,
                                let nickname = temp.last {
                                self.userAccount.addServiceCustomer(serviceCustomer: ServiceCustomer(id: userID, name: nickname))
                            }
                        }
                    }
                    
                    completionHandler(success, self.userAccount)
                }else{
                    self.userAccount.setError(error: SDKError.ACCOUNT_LOGIN)
                    self.userAccount.setMessage(message: "failed to get token")
                    completionHandler(success, self.userAccount)
                }
            }
        }
        
        
    }
 
    public func getAccount() -> UserAccount{
        
        
        return userAccount
    }
    
    public func clearAccount(){
        userAccount = UserAccount()
        userAccount.setError(error: .ACCOUNT_LOAD)
    }
    
    public func updateToken(){
        
        
        
    }
}
