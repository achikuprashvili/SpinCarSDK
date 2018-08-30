//
//  SpincarCrashlyticsLogger.swift
//  SpinCar
//
//  Copyright © 2016 SpinCar. All rights reserved.
//

import Foundation
import Crashlytics


class SpinCarCrashlyticsLogger: NSObject {
    
    let logger: Crashlytics?
    static let SpinCarLogger = SpinCarCrashlyticsLogger()
    
    override init() {
        logger = Crashlytics.init()
    }
    
    func log_non_fatal(_ name: String, reason: AnyObject) {
        // frameArray off CLSStackFrames intentionally empty because it can influence
        // grouping of exceptions. We want non fatals to be unique. Even though we risk 
        // losing some important information.
        // https://docs.fabric.io/appledocs/Crashlytics/Classes/CLSStackFrame.html
        let reason_as_string = objectToString(reason)
        if reason_as_string.count > 0 {
            self.logger?.recordCustomExceptionName(name, reason: reason_as_string, frameArray: [])
            MixpanelManager.trackEvent("Non fatal logged", properties: ["name": name, "reason": reason_as_string])
        }
    }
    
    func set_key(_ key: String, value: AnyObject) {
        if key == "email" {
            self.logger?.setUserEmail(value.description)
        } else {
            let value_as_string = objectToString(value)
            self.logger?.setObjectValue(value_as_string, forKey: key)
        }
    }
    
    func log(_ text: String, varargs: [AnyObject]=[]) {
        var va_list = [CVarArg]()
        for (arg) in varargs {
            let new_arg = objectToString(arg) as CVarArg
            va_list.append(new_arg)
        }
        print(String(format: text, arguments: va_list)) // In case CLSLogv cannot print to console anyway
        CLSLogv(text, getVaList(va_list))
    }
    
    // Internal method
    func objectToString(_ obj: AnyObject) -> String {
        var as_string = ""
        if obj is String {
            as_string = (obj as? String)!
        } else if let _ = obj.description{
            as_string = obj.description
        } else if let _  = obj.debugDescription{
            as_string = obj.debugDescription
        }
        return as_string;
    }

}
