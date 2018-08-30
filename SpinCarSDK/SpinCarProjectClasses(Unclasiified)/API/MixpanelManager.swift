//
//  MixpanelManager.swift
//  SpinCar


import Foundation
import Mixpanel


class MixpanelManager {
    
    // SpinCar's mixpanel token
    fileprivate static let token = "312e66862d229e027494c15ac5461dd9"
    fileprivate static var mixpanel: Mixpanel!
    // Anonymous user if first time launching app
    fileprivate static var isAnonymous = false
    
    // Must be called before any other call to Mixpanel
    static func startMixpanel() {
        // Mixpanel should be initialized with some time before any other 
        // call to its API even though singleton practices dictate lazy initialization. 
        Mixpanel.sharedInstance(withToken: token)
        mixpanel = Mixpanel.sharedInstance()
    }
    
    /**
     
     Set the id and super properties associated with this user.
     
     The id should be the user's log in email if it is not a guest, otherwise it should be its registered email
     
     - Parameter id: the id associated with this user, nil if none
     - Parameter isGuest: whether the user is a guest or not
 
    */
    static func setIDAndProperties(_ id: String?, isGuest: Bool) {
        // Clear current super properties and id
        mixpanel.reset()
        
        let uuid = UIDevice.current.identifierForVendor!.uuidString
        var properties: [AnyHashable: Any] = ["UUID": uuid]
        if let id = id {
            mixpanel.identify(id)
            properties["Email"] = id
            mixpanel.people.set(["$name": id, "$email": id, "Guest": isGuest])
            isAnonymous = false
        } else {
            // If nil then first time launching app, use mixpanel default id
            // Note that to use mixpanel people we need to explicitly call identify
            // even if we are not changing the id
            mixpanel.identify(uuid)
            isAnonymous = true
        }
        
        setSuperProperties(properties)
    }
    
    /**
     
     Set up id and properties for user at log in.
     
     - Parameter id: The id the the user wil be identified as
     - Parameter isGuest: whether the user is a guest or not
     - Parameter properties: Any additional properties that should be associated with the user
     
     */
    static func userLoginWithEmail(_ id: String, isGuest: Bool, properties: [AnyHashable: Any]=[:]) {
        if isAnonymous {
            // if no email was associated with user, link mixpanel generated id with new id (email)
            mixpanel.createAlias(id, forDistinctID: mixpanel.distinctId)
        }
        // Set the mixpanel id and tracking properties
        setIDAndProperties(id, isGuest: isGuest)
        // Set the user's properties
        mixpanel.people.set(properties)
        // Track if user logged in or continued as guest after registration
        trackEvent("Log in", properties: ["As guest": isGuest])
    }
    
    /**
     
     Set up id and properties for new user at sign up.
     
     The user is registered to Mixpanel as a guest
     
     - Parameter id: The id the the user wil be identified as
     - Parameter properties: Any additional properties that should be associated with the user
     
     */
    static func newUserSignUpWithId(_ id: String, properties: [AnyHashable: Any]=[:]) {
        if isAnonymous {
            mixpanel.createAlias(id, forDistinctID: mixpanel.distinctId)
        }
        
        setIDAndProperties(id, isGuest: true)
        
        mixpanel.people.set(properties)
        
        trackEvent("Registered")
    }
    
    static func trackEvent(_ eventName: String, properties: [AnyHashable: Any]=[:]) {
        var properties = properties
        properties["Timestamp"] = Date()
        #if DEBUG
            properties["Debug"] = true
        #endif
        mixpanel.track(eventName, properties: properties)
    }
    
    static func setSuperProperties(_ superProperties: [AnyHashable: Any]) {
        mixpanel.registerSuperProperties(superProperties)
    }
    
    static func timeEvent(_ eventName: String) {
        mixpanel.timeEvent(eventName)
    }

}
