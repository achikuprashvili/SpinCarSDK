//
//  Configuration.swift
//  SpinCar
//
//  Created by Samuel Skelton on 1/24/16.
//  Copyright © 2016 SpinCar. All rights reserved.
//

import Foundation

struct Configuration {
    static var BaseURL: String {
        get {
            return "https://spincar-app-api.spincar.com/"
            #if DEBUG
                /*
                NOTE: This requires developers to add an environment variable to their DEBUG scheme.
                Do this by Product -> Scheme -> Edit Scheme, and adding your local IP address to
                the environment variables under the "Arguments" tab for the key "ManagerIP".
                */
                return "https://spincar-app-api.spincar.com/"
//                return ProcessInfo.processInfo.environment["ManagerIP"]!
            #elseif RELEASE
                return "https://spincar-app-api.spincar.com/"
            #endif
        }
    }
    static var GUEST_EMAIL: String {
        get {
            return "guest@spincar.com"
        }
    }
    static var GUEST_PASSWORD: String {
        get {
            return "guest123"
        }
    }
    static var ADMIN_PASSWORD: String {
        get {
            return "cuse"
        }
    }
}
