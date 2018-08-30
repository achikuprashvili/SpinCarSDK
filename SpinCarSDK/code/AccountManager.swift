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
    private init(){
        _ = userAccount.setError(error: SDKError.ACCOUNT_LOGIN)
    }
    public static let shared = AccountManager()
    private var userAccount: UserAccount = UserAccount()
    public func login(email: String, password: String, completionHandler: @escaping (Bool, UserAccount) -> ()){
        HTTPClient.login(email: email, password: password) { (success, response) in
            if (!success){
                let userAccount: UserAccount = UserAccount()
                _ = userAccount.setError(error: SDKError.ACCOUNT_LOGIN).setMessage(message: "failed to login")

                completionHandler(success, userAccount)
                
            }else{
                let userAccount: UserAccount = UserAccount()
                userAccount.setShootWalkaround(shootWalkaround: (response["shoot_walkaround"] as? Bool) ?? true)
                if let token = response["token"] as? String {
                    
                    userAccount.setEmail(email: email)
                    userAccount.setPassword(password: password)
                    userAccount.setToken(token: token)
                    userAccount.setTokenUpdateTime(tokenUpdateTime: Date())
                    completionHandler(success, userAccount)
                }else{
                    userAccount.setError(error: SDKError.ACCOUNT_LOGIN)
                    userAccount.setMessage(message: "failed to get token")
                    completionHandler(success, userAccount)
                }
            }
        }
        
        
    }
 
    public func getAccount() -> AnyObject{
        
        
        return NSObject()
    }
    
    public func clearAccount() -> AnyObject{
        
        
        return NSObject()
    }
    
    public func updateToken() -> AnyObject{
        
        
        return NSObject()
    }
}
