//
//  Constants.swift
//  SpinCar
//
//  Created by Samuel Skelton on 1/31/16.
//  Copyright © 2016 SpinCar. All rights reserved.
//

import Foundation

struct Constants {
    static var DocumentsDirectory: URL {
        get {
            let documentsURL = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
            return documentsURL
        }
    }
    
    static var SpinDirectory: URL {
        get {
            return Constants.DocumentsDirectory.appendingPathComponent("spins")
        }
    }
    
    static var SpinsKeyedArchiverFileURL: URL {
        get {
            return Constants.DocumentsDirectory.appendingPathComponent(".spins.archive")
        }
    }
    
    static var GuestMaxSpins: Int {
        return 5
    }
    
    static let srpString = NSLocalizedString(
        "SRP",
        comment: "The search results page photo of a car"
    )
    
}
