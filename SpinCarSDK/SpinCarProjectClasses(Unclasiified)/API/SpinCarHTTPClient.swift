//
//  SpinCarHTTPClient.swift
//  SpinCar
//

import Foundation
import Alamofire

protocol SpinCarHTTPClientDelegate {
    func retryLastRequest()
}

class SpinCarHTTPClient {
    var previousEndpoint: Endpoint?
    
    static let sharedManager = SpinCarHTTPClient()
    let ignored_errors = [NSURLErrorBadURL, NSURLErrorNotConnectedToInternet]
    let bundle = Bundle.main.bundleIdentifier!
    let Common = CommonHelpers.CommonHelper
    let crashlyticsLogger = SpinCarCrashlyticsLogger.SpinCarLogger
    var alamofireManager: Alamofire.SessionManager?
    let uploadFailedTitle = NSLocalizedString(
        "Upload_Failed",
        comment: "Alert title indicating a user's upload has failed"
    )
    
    enum Endpoint: String {
        case None = ""
        case Login = "auth/login"
        case Refresh = "auth/login "
        case UploadStatus = "upload/status"
        case SignMedia = "spins/sign-upload"
        case UploadFinished = "spins/upload-finished"
        case NewUserEmail = "new-user-email"
        case HotspotString = "hotspot-string"
        case ShareYoutubeUpload = "/share-youtube-upload"
        case VehicleLookup = "vehicle/lookup"
        case GetFeatures = "get_features"
        
        var URL: String {
            get {
                return self.rawValue
            }
        }
    }
    
    init() {
        let randomString = ProcessInfo.processInfo.globallyUniqueString as NSString
        let configuration = URLSessionConfiguration.background(
            withIdentifier: "\(bundle)-background-session-api-\(randomString)"
        )
        // A background session is safer in case the app is sent to the background.
        // However we need to set a lower timeout for resource intervals.
        // https://forums.developer.apple.com/thread/22690
        // The background session will continue trying even if it does not receive an answer from a server.
        // and it will keep trying until timeoutIntervalForResource. (which is 7 days by default)
        // The advantage is that this session will work in the background and not fail immediately if the internet connection drops momentarily.
        configuration.timeoutIntervalForResource = 172800  // 48 Hours
        self.alamofireManager = Alamofire.SessionManager(configuration: configuration)
    }
    
    @objc func updateGatedFeatures() {
        self.request(method: .post, endpoint: .GetFeatures) { (success, response) in
            if let response = response as? [String: Any], success {
                self.crashlyticsLogger.log("Updated Feature Capabilities: %@", varargs: [response as AnyObject])
                var availableFeatures: [String: Bool] = [:]
                
                if let gatedFeatures = response["features_for"] as? [[String: Any]] {
                    for feature in gatedFeatures {
                        if let featureName = feature["name"] as? String {
                            availableFeatures[featureName] = (feature["enabled"] as? Bool) ?? false
                        }
                    }
                }

                let features = [
                    "AR": availableFeatures["ar_capture"] ?? false,
                    "ImageDepthBlur": availableFeatures["image_depth_capture"] ?? false,
                    "VideoStabilization": availableFeatures["video_stabilization"] ?? false,
                    "RicohLiveView": availableFeatures["ricoh_live_preview"] ?? false
                ]
                
                UserDefaults.standard.set(features, forKey: "gatedFeatures")
            }
        }
    }
    
    func login(email: String, password: String, completionHandler: @escaping ((_ success: Bool, _ response: [String: AnyObject]) -> Void)) {
        var parameters: [String: AnyObject] = [:]
        parameters["email"] = email as AnyObject
        parameters["password"] = password as AnyObject
        self.request(method: .post, parameters: parameters, endpoint: .Login) { (requestSuccess, response) -> Void in
            if !requestSuccess {
                if let response = response as? String {
                    self.crashlyticsLogger.log("REQUEST FOR LOGIN FAILED: %@", varargs: [response as AnyObject])
                    
                }
                completionHandler(false, [:])
            } else {
                if let response = response as? [String: AnyObject] {
                   
                    self.crashlyticsLogger.log("REQUEST SUCCESS: %@", varargs: [response as AnyObject])
                    
                    let shoot_walkaround = (response["shoot_walkaround"] as? Bool) ?? true
                    self.crashlyticsLogger.set_key("shoot_walkaround", value: shoot_walkaround as AnyObject)
                    
                    // Feature Flags
                    // Note: Subject to API changes
                    let arCapture = (response["ar_enabled"] as? Bool) ?? false
                    let depthCapture = (response["idc_enabled"] as? Bool) ?? false
                    
                    let features = [
                        "AR": arCapture,
                        "ImageDepthBlur": depthCapture
                    ]
                    
                    if let token = response["token"] as? String {
                        let emailSaveSuccessful: Bool = KeychainWrapper.setString(email, forKey: SecAttrAccount)
                        let tokenSaveSuccessful: Bool = KeychainWrapper.setString(token, forKey: SecAttrGeneric)
                        let passwordSaveSuccessful: Bool = KeychainWrapper.setString(password, forKey: SecValueData)
                        
                        if emailSaveSuccessful && tokenSaveSuccessful && passwordSaveSuccessful {
                            self.crashlyticsLogger.log("All saves successful!")
                        }
                    }
                    
                    let defaults = UserDefaults.standard
                    defaults.set(shoot_walkaround, forKey: "shoot_walkaround")
                    defaults.set(features, forKey: "gatedFeatures")
                    
                    let lot_service_customers = response["lot_service_customers"] as? String
                    if lot_service_customers != nil {
                        defaults.set(lot_service_customers, forKey: "lot_service_customers")
                    } else {
                        // If user is not a lot service user, remove the key from the dictionary
                        defaults.removeObject(forKey: "lot_service_customers")
                    }
                    let hasLoginKey = defaults.bool(forKey: "hasLoginKey")
                    if !hasLoginKey || hasLoginKey == false {
                        defaults.setValue(true, forKey: "hasLoginKey")
                    }
                    
                    completionHandler(true, response)
                }
            }
        }
    }
    
    func getUploadStatus(vins: [String], video_type: String, completionHandler: @escaping ((_ success: Bool, _ uploads: [String: AnyObject]) -> Void)) {
        var parameters: [String: AnyObject] = [:]
        // For multi-account user, send api parameters as [userID: [list of vins]]
        // If user is a multi-account user, then vins will contain a list of "userID:vin" instead of just vins
        if let _ = UserDefaults.standard.string(forKey: "lot_service_customers"),
        let first = vins.first,
        first.contains(":") {
            var multiAccountVins: [String: [String]] = [:]
            for vin in vins {
                // We don't support switching back and forth between multi-user and non-multi-user. If we detect a non-multi-user spin, exit the function:
                guard vin.contains(":") else { return }
                let userIDtoVins = vin.components(separatedBy: ":")
                if let _ = multiAccountVins[userIDtoVins[0]] {
                    // We don't need to safely unwrap multiAccountVins[userIDtoVins[0]] because it's checked in the if let
                    multiAccountVins[userIDtoVins[0]]!.append(userIDtoVins[1])
                } else {
                    // Add the userid as a key
                    multiAccountVins[userIDtoVins[0]] = [userIDtoVins[1]]
                }
            }
            var vins = ""
            do {
                let data = try JSONSerialization.data(withJSONObject: multiAccountVins, options: [])
                vins = String(data: data, encoding: String.Encoding.utf8) ?? ""
            } catch {
                self.crashlyticsLogger.log("Unable to serialize userid:vins as a JSON object.")
            }
            parameters["customer_ids_vins"] = vins as AnyObject?
        } else {
            parameters["vins"] = vins as AnyObject?
        }
        parameters["video_type"] = video_type as AnyObject?
        self.request(method: .post, parameters: parameters, endpoint: .UploadStatus) { (_ requestSuccess, _ response) -> Void in
            if !requestSuccess {
                completionHandler(false, [:])
            } else {
                self.crashlyticsLogger.log("Checking if an upload status response was received")
                if let response = response,
                let uploadData = response["upload_statuses"] as? [String: AnyObject] {
                    self.crashlyticsLogger.log("Upload status response: %@", varargs: [response])
                    completionHandler(true, uploadData)
                }
            }
        }
    }
    
    func signVideoUpload(saveable: SaveableMO, role: String, completionHandler: @escaping ((_ success : Bool, _ response: [String: AnyObject]?) -> Void)) {
        var parameters: [String: AnyObject] = [:]
        parameters["vin"] = saveable.uploadID! as AnyObject?
        parameters["role"] = role as AnyObject?
        parameters["content_type"] = "video/mpeg" as AnyObject?
        if let accountID = saveable.accountID {
            parameters["lot_service_customer_id"] = accountID as AnyObject
        }
        
        self.request(method: .post, parameters: parameters, endpoint: .SignMedia) { (requestSuccess, response) -> Void in
            if !requestSuccess {
                if let response = response {
                    self.crashlyticsLogger.log("SIGN REQUEST FAILED: %@", varargs: [response])
                    var description = response as? String
                    if description!.contains("missing token") {
                        description = NSLocalizedString(
                            "Missing_Token_Message",
                            comment: "Alert message informing user that they need to logout then log back in to continue"
                        )
                    }
                    
                }
                completionHandler(false, nil)
            } else {
                if let response = response as? [String: AnyObject] {
                    if let formData = response["form_data"] as? [String: AnyObject] {
                        completionHandler(true, formData)
                    }
                }
            }
        }
    }
    
    func signJsonUpload(saveable: SaveableMO, jsonInformation: String, completionHandler: @escaping ((_ success : Bool, _ response: [String: AnyObject]?) -> Void)) {
        // NOTE: Add a unit test for this
        var parameters: [String: AnyObject] = [:]

        parameters["vin"] = saveable.uploadID! as AnyObject
        parameters["type"] = jsonInformation as AnyObject
        parameters["content_type"] = "application/json" as AnyObject

        self.request(method: .post, parameters: parameters, endpoint: .SignMedia) { (requestSuccess, response) -> Void in
            if !requestSuccess {
                if let response = response {
                    self.crashlyticsLogger.log("SIGN REQUEST FAILED: %@", varargs: [response])
                    var description = response as? String
                    if description!.contains("missing token") {
                        description = NSLocalizedString(
                            "Missing_Token_Message",
                            comment: "Alert message informing user that they need to logout then log back in to continue"
                        )
                    }
                }
                completionHandler(false, nil)
            } else {
                if let response = response as? [String: AnyObject] {
                    if let formData = response["form_data"] as? [String: AnyObject] {
                        completionHandler(true, formData)
                    }
                }
            }
        }
    }
    
    func signPhotoUploads(spin: SpinMO, index: Int, photoType: String, closeupTag: String?, completionHandler: @escaping ((_ success: Bool, _ response: [String: AnyObject]?) -> Void)) {
        var parameters: [String: AnyObject] = [:]
        parameters["vin"] = spin.uploadID! as AnyObject
        parameters["content_type"] = "image/jpeg" as AnyObject
        parameters["group"] = photoType as AnyObject
        parameters["index"] = index as AnyObject
        parameters["closeup_tag"] = closeupTag as AnyObject
        if let accountID = spin.accountID {
            parameters["lot_service_customer_id"] = accountID as AnyObject
        }
        
        self.request(method: .post, parameters: parameters, endpoint: .SignMedia) { (requestSuccess, response) -> Void in
            if !requestSuccess {
                if let response = response {
                    self.crashlyticsLogger.log("SIGN REQUEST FAILED: %@", varargs: [response])
                    var description = response as? String
                    if description!.contains("missing token") {
                        description = NSLocalizedString(
                            "Missing_Token_Message",
                            comment: "Alert message informing user that they need to logout then log back in to continue"
                        )                    }

                }
                completionHandler(false, nil)
            } else {
                if let response = response as? [String: AnyObject] {
                    if let formData = response["form_data"] as? [String: AnyObject] {
                        completionHandler(true, formData)
                    }
                }
            }
        }
    }
    
    func signRicohUpload(spin: SpinMO, completionHandler: @escaping ((_ success: Bool, _ response: [String: AnyObject]?) -> Void)) {
        var parameters: [String: AnyObject] = [:]
        parameters["vin"] = spin.uploadID! as AnyObject
        parameters["content_type"] = "image/jpeg" as AnyObject
        parameters["group"] = "pano" as AnyObject
        if let accountID = spin.accountID {
            parameters["lot_service_customer_id"] = accountID as AnyObject
        }
        
        self.request(method: .post, parameters: parameters, endpoint: .SignMedia) { (requestSuccess, response) -> Void in
            if !requestSuccess {
                if let response = response {
                    self.crashlyticsLogger.log("RICOH SIGN REQUEST FAILED: %@", varargs: [response])
                    var description = response as? String
                    if description!.contains("missing token") {
                        description = NSLocalizedString(
                            "Missing_Token_Message",
                            comment: "Alert message informing user that they need to logout then log back in to continue"
                        )
                    }

                }
                completionHandler(false, nil)
            } else {
                if let response = response as? [String: AnyObject] {
                    if let formData = response["form_data"] as? [String: AnyObject] {
                        completionHandler(true, formData)
                    }
                }
            }
        }
    }
    
    func uploadFinished(saveable: SaveableMO, completionHandler: @escaping ((_ success : Bool) -> Void)) {
        var parameters: [String: AnyObject] = [:]
        parameters["vin"] = saveable.id! as AnyObject?
        parameters["role"] = saveable.type as AnyObject
        if let accountID = saveable.accountID {
            parameters["lot_service_customer_id"] = accountID as AnyObject
        }
        if let _ = UserDefaults.standard.object(forKey: "Priority") {
            parameters["priority_password"] = Configuration.ADMIN_PASSWORD as AnyObject
        }
        
        if let spin = saveable as? SpinMO {
            var hotspotString = "[{}]" as NSString
            
            if let closeups = spin.closeups {
                hotspotString = spin.convertHotspotDataToString(hotspotArray: closeups) as NSString
            }

            parameters["hotspots"] = hotspotString
        }

        var tripodEnabled = false
        
        if let defaultSettings = UserDefaults.standard.object(forKey: "settings") as? [String: AnyObject] {
            tripodEnabled = (defaultSettings[SettingsConstants.tripodModeEnabled] as? Bool) ?? false
        }
        parameters["deshake_disabled"] = tripodEnabled as AnyObject
        if let exteriorView = (saveable as? SpinMO)?.getViewOfType(viewType: ExteriorViewMO.self),
        let assets = exteriorView.assets,
        let asset = assets.first,
        let url = asset.fullURL,
        let path = url.path {
            if path.contains(".mov") {
                parameters["exterior_media"] = "video" as AnyObject
            } else if path.contains(".jpeg") {
                parameters["exterior_media"] = String(assets.count) as AnyObject
            }
        }
        
        self.request(method: .post, parameters: parameters, endpoint: .UploadFinished) { (requestSuccess, response) -> Void in
            if !requestSuccess {
                if let response = response {
                    self.crashlyticsLogger.log("REQUEST FAILED: %@", varargs: [response])
                }
                completionHandler(false)
            } else {
                self.crashlyticsLogger.log("RESPONSE: %@", varargs: [response!])
                if let response = response as? String {
                    if response == "" {
                        completionHandler(true)
                    } else {
                        completionHandler(false)
                    }
                } else {
                    completionHandler(true)
                }
            }
        }
    }
    
    func newUserEmail(name: String, email: String, phone: String, completionHandler: @escaping (_ success: Bool) -> Void){
        var parameters: [String: AnyObject] = [:]
        parameters["userName"] = name as AnyObject
        parameters["userEmail"] = email as AnyObject
        parameters["userPhone"] = phone as AnyObject
        self.request(method: .post, parameters: parameters, endpoint: .NewUserEmail) { (requestSuccess, response) in
            if !requestSuccess {
                if let response = response {
                    self.crashlyticsLogger.log("REQUEST FAILED: %@", varargs: [response])
                }
                completionHandler(false)
            } else {
                self.crashlyticsLogger.log("RESPONSE: %@", varargs: [response!])
                if let response = response as? String {
                    if response == "" {
                        completionHandler(true)
                    } else {
                        completionHandler(false)
                    }
                } else {
                    completionHandler(true)
                }
            }
        }
    }
    
    func getHotspotString( completionHandler: @escaping ((_ success: Bool, _ response: AnyObject?) -> Void)) {
        self.request(method: .get, endpoint: .HotspotString, completionHandler: { (requestSuccess, response) -> Void in
            if !requestSuccess {
                if let response = response {
                    self.crashlyticsLogger.log("Couldn't get hotspot string. Reason: %@", varargs: [response])
                }
                completionHandler(false, response)
            } else {
                self.crashlyticsLogger.log("Successfully fetched hotspot string")
                if let responseDict = (response as? [String: AnyObject]),
                let hotspotString = responseDict["hotspot_string"] as? String {
                    let validatedHotspotString = self.Common.removeDuplicateHotspots(hotspotString: hotspotString)
                    UserDefaults.standard.setValue(validatedHotspotString, forKey: "hotspots")
                    completionHandler(true, response)
                }
            }
        })
    }
    
    func share_youtube_upload(vin: String, phone: String, email: String, youtubeDescription: String, message: String, videoType: String, completionHandler: @escaping ((_ success: Bool, _ response: AnyObject?) -> Void)) {
        /*
         * Share on YouTube endpoint.
         * Call this function AFTER signing and uploading a video file.
         * Specify SMS and/or Email - All other parameters required.
         * vin - Same meaning as spin.id (A vehicle identifier).
         * youtubeDescription is a JSON object (Will be converted to YAML in the backend) with certain attributes.
         * message is custom text for the body of text generated. This will be displayed before the GardX link.
         */
        var parameters: [String: AnyObject] = [:]
        parameters["sms"] = phone as AnyObject
        parameters["email"] = email as AnyObject
        parameters["youtube_description"] = youtubeDescription as AnyObject
        parameters["message"] = message as AnyObject
        parameters["vin"] = vin as AnyObject
        parameters["video_type"] = videoType as AnyObject

        self.request(method: .post, parameters: parameters, endpoint: .ShareYoutubeUpload, completionHandler: { (requestSuccess, response) -> Void in
            if !requestSuccess {
                if let response = response {
                    self.crashlyticsLogger.log("Error posting to share on youtube endpoint. Reason: %@", varargs: [response])
                }
                completionHandler(false, response)
            } else {
                
                if let response = response {
                    var success = false
                    
                    if let resp = response as? [String: AnyObject] {
                        if let resp2 = resp["response"] as? [String: AnyObject] {
                            success = (resp2["success"] as? Bool ?? false)!
                        }
                    }
                    
                    if success {
                        self.crashlyticsLogger.log("Successfully posted to share on youtube endpoint")
                    }
                    completionHandler(success, response)
                }
            }
        })
    }
    
    func vehicleLookup(saveable: SaveableMO, completionHandler: @escaping ((_ success: Bool, _ response: AnyObject?) -> Void)) {
        var parameters: [String: AnyObject] = [:]
        parameters["vin"] = saveable.id! as AnyObject
        self.request(method: .post, parameters: parameters, endpoint: .VehicleLookup, completionHandler: { (requestSuccess, response) -> Void in
            if !requestSuccess {
                // This means that the VIN was not found
                if let response = response {
                    self.crashlyticsLogger.log("Couldn't find vehicle with VIN: \(parameters["vin"]!). Reason: %@", varargs: [response])
                }
                completionHandler(false, response)
            } else {
                // Otherwise VIN was found
                self.crashlyticsLogger.log("Found vehicle for VIN: \(String(describing: parameters["vin"])).")
                completionHandler(true, response)
            }
        })
    }
    
    func refreshToken(method: HTTPMethod, parameters: [String: AnyObject] = [:], endpoint: Endpoint, completionHandler: @escaping (_ requestSuccess: Bool, _ response: AnyObject?) -> Void, requestCompletionHandler: @escaping ((_ success : Bool) -> Void)) {
        self.request(method: .post, parameters: [:], endpoint: .Refresh) { (requestSuccess, response) -> Void in
            if !requestSuccess {
                if let response = response {
                    self.crashlyticsLogger.log("TOKEN REFRESH FAILED: %@", varargs: [response])
                }
                requestCompletionHandler(false)
            } else {
                if let response = response {
                    self.crashlyticsLogger.log("REQUEST SUCCESS: %@", varargs: [response])
                    if let token = response["token"] as? String {
                        let tokenRemoveSuccessful: Bool = KeychainWrapper.removeObjectForKey(SecAttrGeneric)
                        let tokenSaveSuccessful: Bool = KeychainWrapper.setString(token, forKey: SecAttrGeneric)
                        if tokenRemoveSuccessful && tokenSaveSuccessful {
                            self.crashlyticsLogger.log("Token save successful!")
                        }
                    }
                    self.crashlyticsLogger.log("HAS KEY? %@", varargs:[KeychainWrapper.hasValueForKey(SecAttrGeneric) as AnyObject])
                }
                
                // Retry original request:
                self.request(method: method, parameters: parameters, endpoint: endpoint, completionHandler: completionHandler)
            }
        }
    }
    
    fileprivate func request(method: HTTPMethod, parameters: [String: Any] = [:], endpoint: Endpoint, completionHandler: @escaping (_ requestSuccess: Bool, _ response: AnyObject?) -> Void) {
        self.crashlyticsLogger.log("Trying request for: %@", varargs: [endpoint.URL as AnyObject])
        var endpoint = endpoint
        var parameters = parameters
        
        var headers: [String: String] = [:]
        if endpoint == .Refresh {
            parameters = parameters as [String: AnyObject]
            if let email = KeychainWrapper.string(SecAttrAccount) {
                parameters["email"] = email as AnyObject
            } else {
                self.crashlyticsLogger.log("Error loading email credentials!")
            }
            if let password = KeychainWrapper.string(SecValueData) {
                parameters["password"] = password as AnyObject
            } else {
                self.crashlyticsLogger.log("Error loading password credentials!")
            }
            endpoint = .Login
        } else if endpoint != .Login {
            if let token = KeychainWrapper.string(SecAttrGeneric) {
                headers["x-token"] = token
            }
        }
        self.crashlyticsLogger.log("headers: %@", varargs: [headers as AnyObject])
        self.crashlyticsLogger.log("parameters: %@", varargs: [parameters as AnyObject])
        
        
        let requestURL = "\(Configuration.BaseURL)\(endpoint.URL)"
        Alamofire.request(requestURL, method: method, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers).responseJSON { response in
            switch response.result {
            case .success(let JSON):
                if let jsonResult = JSON as? [String: AnyObject] {
                    self.crashlyticsLogger.log("JSON RESULT: %@", varargs: [jsonResult as AnyObject])
                    if let failureReason = jsonResult["reason"] as? String {
                        self.crashlyticsLogger.log("REQUEST FAIL: %@", varargs: [failureReason as AnyObject])
                        if (failureReason == "bad or expired token" || failureReason == "missing token") && self.previousEndpoint != .Refresh {
                            self.previousEndpoint = .Refresh
                            self.refreshToken(method: method, parameters: parameters as [String : AnyObject], endpoint: endpoint, completionHandler: completionHandler, requestCompletionHandler: { (success) -> Void in
                                if !success {
                                    completionHandler(false, failureReason as AnyObject)
                                }
                            })
                            self.previousEndpoint = .none
                        } else {
                            self.previousEndpoint = .none
                            if (failureReason as? String) != "vehicle not found" {
                                self.crashlyticsLogger.log_non_fatal("Request Error", reason: "\(failureReason)" as AnyObject)
                            }
                            completionHandler(false, failureReason as AnyObject)
                        }
                    } else {
                        completionHandler(true, jsonResult as AnyObject)
                    }
                } else {
                    completionHandler(true, nil)
                }
            case .failure(let error):
                if let resp = response.response {
                    self.crashlyticsLogger.log("Error in response: %@", varargs: [resp])
                    self.crashlyticsLogger.log_non_fatal("Response Error", reason: resp.statusCode as AnyObject)
                }
                else if !self.ignored_errors.contains((error as NSError).code)
                {
                    self.crashlyticsLogger.log("ERROR PARAMS: %@, HEADERS: %@", varargs: [parameters as AnyObject, headers as AnyObject])
                    let reason = "Error code: \((error as NSError).code) \(error.localizedDescription) URL: \(requestURL)"
                    // Only show error code and request url instead of entire error description which will be in the logs anyway.
                    // (Entire description contains memory addresses which will make every non fatal unique
                    // when we just want the error code and url to be unique)
                    self.crashlyticsLogger.log_non_fatal("Request Failed", reason: reason as AnyObject)
                }
                // Always try to display an status code if one exists
                // (Not all NSERRORs correspond to HTTP status error codes)
                var errorString = ""
                if let statusCode = response.response?.statusCode {
                    errorString = NSLocalizedString(
                        "Status_Code",
                        comment: "Apple's status code of the error"
                        ) + String(statusCode)
                }
                // If no error code exists display the NSERROR's description
                if errorString.isEmpty {
                    errorString = "Error: \(error.localizedDescription)"
                }
                completionHandler(
                    false,
                    NSLocalizedString(
                        "Request_Failed_Message",
                        comment: "Alert title indicating the request has failed"
                        ) + errorString as AnyObject
                )
            }
        }
    }
    
    // FIXME: The API Client should not be responsible for showing alerts.
    // Have each function return the proper message/title in its callback and display the alert in the VC where the API call originated.

    
    fileprivate func delay(_ delay: Double, closure: @escaping ()->()) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
    }
}
