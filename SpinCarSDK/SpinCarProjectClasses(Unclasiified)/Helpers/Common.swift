//
//  Common.swift
//  SpinCar
//
//  Utility functions that don't quite fit anywhere.
//  This is not for functions used in multiple view controllers - those should be part of the SpinCarViewController class.
//
//  Copyright © 2016 SpinCar. All rights reserved.
//

import Foundation
import SystemConfiguration
import CommonCrypto

extension Int {
    func hexedString() -> String {
        return NSString(format:"%02x", self) as String
    }
}

extension Data {
    func hexedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }

    func MD5() -> Data {
        var result = Data(count: Int(CC_MD5_DIGEST_LENGTH))
        _ = result.withUnsafeMutableBytes {resultPtr in
            self.withUnsafeBytes {(bytes: UnsafePointer<UInt8>) in
                CC_MD5(bytes, CC_LONG(count), resultPtr)
            }
        }
        return result
    }
}

extension String {
    func MD5() -> String {
        let messageData = self.data(using:.utf8)!
        var digestData = Data(count: Int(CC_MD5_DIGEST_LENGTH))
        
        _ = digestData.withUnsafeMutableBytes { digestBytes in
            messageData.withUnsafeBytes { messageBytes in
                CC_MD5(messageBytes, CC_LONG(messageData.count), digestBytes)
            }
        }
        
        return digestData.map { String(format: "%02hhx", $0) }.joined()
    }

    func SHA1() -> String {
        let data = self.data(using: String.Encoding.utf8)!
        var digest = [UInt8](repeating: 0, count:Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA1($0, CC_LONG(data.count), &digest)
        }
        let hexBytes = digest.map { String(format: "%02hhx", $0) }
        return hexBytes.joined()
    }
}


class CommonHelpers {
    let crashlyticsLogger = SpinCarCrashlyticsLogger.SpinCarLogger
    static let CommonHelper = CommonHelpers()

    func convertStringToJSON(_ text: String) -> Any? {
        if let data = text.data(using: String.Encoding.utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: [])
            } catch {}
        }
        return nil
    }
    
    func removeDuplicateHotspots(hotspotString: String) -> String {
        guard let hotspotJSON = self.convertStringToJSON(hotspotString) as? [[String: Any]] else { return hotspotString }
        var validatedJSON: [[String: Any]] = []
        var validatedJSONString: String?
        var names = Set<String>()
        
        for hotspot in hotspotJSON {
            if let name = hotspot["name"] as? String {
                if !names.contains(name.lowercased()) {
                    validatedJSON.append(hotspot)
                    names.insert(name.lowercased())
                }
            } else {
                validatedJSON.append(hotspot)
            }
        }
        if JSONSerialization.isValidJSONObject(validatedJSON) {
            if let jsonData = try? JSONSerialization.data(withJSONObject: validatedJSON) as Data {
                validatedJSONString = String(data: jsonData as Data, encoding: String.Encoding.utf8)
            }
        }
        return validatedJSONString ?? hotspotString
    }

    func makeConsecutiveIndex(_ dictToChange: [Int: String]) -> [Int: String]? {
        var consecutivized: [Int: String] = [:]
        var count = 0
        for index in dictToChange.keys.sorted() {
            let entry = dictToChange[index]
            consecutivized[count] = entry
            count += 1
        }
        return consecutivized
    }

    func isConnectionAvailable(useWifi: Bool = true) -> Bool{
        let reachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, "www.apple.com")
        var flags : SCNetworkReachabilityFlags = SCNetworkReachabilityFlags()

        if SCNetworkReachabilityGetFlags(reachability!, &flags) == false {
            return false
        }

        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        let isWWAN = flags.contains(.isWWAN)

        return (isReachable && !needsConnection && (!isWWAN || !useWifi))
    }

    func getFreeStorageInBytes() -> Int64? {
        let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        if let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: documentDirectoryPath.last!) {
            if let freeSize = systemAttributes[FileAttributeKey.systemFreeSize] as? NSNumber {
                return freeSize.int64Value
            }
        }
        return 0
    }
    
    func getArchiveURL(_ currentRole: String) -> URL {
        return Constants.SpinsKeyedArchiverFileURL
    }
    
    func getStorageSpace() -> String {
        do {
            let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String)
            let space = (systemAttributes[FileAttributeKey.systemSize] as? NSNumber)?.int64Value
            let freeSpace = (systemAttributes[FileAttributeKey.systemFreeSize] as? NSNumber)?.int64Value
            return ByteCountFormatter.string(fromByteCount: space! - freeSpace!, countStyle: ByteCountFormatter.CountStyle.binary)
        } catch {
            return "1"
        }
    }

    func fileMD5(_ path: String) -> String {
        var ret = "".MD5()
        if FileManager.default.fileExists(atPath: path) {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                ret = data.MD5().hexedString()
            } catch {
                self.crashlyticsLogger.log("Error creating an etag hash-value from MD5")
            }
        }
        return ret
    }

    func fileMD5(_ path: URL) -> String {
        var ret = "".MD5()
        let data = try? Data(contentsOf: path)
        if let unwrappedData = data {
            ret = unwrappedData.MD5().hexedString()
        }
        return ret
    }
}

class BackgroundTaskHelper {

    var task: UIBackgroundTaskIdentifier?
    let logger: SpinCarCrashlyticsLogger?

    init (logger: SpinCarCrashlyticsLogger) {
        self.task = UIBackgroundTaskInvalid
        self.logger = logger
    }

    func registerBackgroundTask() {
        task = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            self.endBackgroundTask()
        })
        logger!.log("Registering background task id: %@", varargs: [task! as AnyObject])
    }

    func endBackgroundTask() {
        guard let _ = self.task else {
            return
        }
        logger!.log("Ending background task id: %@", varargs: [task! as AnyObject])
        UIApplication.shared.endBackgroundTask(task!)
        task = UIBackgroundTaskInvalid
    }

}
