//
//  SDKResult.swift
//  SpinCarSDK
//
//  Created by Archil Kuprashvili on 8/28/18.
//

import Foundation

open class SDKResult {
    
    private var error:SDKError = .NO_ERROR
    private var statusCode: Int = 0
    private var message: String = "No message"
//    private var cause: Throwable!
//
    public init(result: SDKResult) {
        
        self.error = result.error
        self.statusCode = result.statusCode
        self.message = result.message
//        self.cause = result.cause;
    }
    
    open func getError() -> SDKError  {
        return error
    }
    
    open func getStatusCode() -> Int{
        return statusCode
    }
    
    open func getMessage() -> String{
        return message
    }
//      resume
//    @Nullable
//    public Throwable getCause() {
//    return cause;
//    }
    open func isValid() -> Bool{
        return error == .NO_ERROR
    }
    
    public func setError(error: SDKError) -> SDKResult  {
        self.error = error
        return self
    }
    
    public func setStatusCode(statusCode: Int) -> SDKResult{
        self.statusCode = statusCode
        return self
    }
    
    public func setMessage(message: String) -> SDKResult {
        self.message = message
        return self
    }
    init() {
        
    }
    

}
