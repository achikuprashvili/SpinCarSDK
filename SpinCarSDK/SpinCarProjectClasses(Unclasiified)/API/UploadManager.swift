//
//  UploadManager.swift
//  SpinCar
//

import CoreData
import Foundation
import Alamofire

protocol UploadManagerDelegate {
    func uploadComplete(_ success: Bool, saveable: SaveableMO, hideAlert: Bool)
    func progressUpdate(_ percentComplete: Float, dataID: String!)
    func uploadCancelled(saveable: SaveableMO)
}

class UploadManager : NSObject {
    var delegate: UploadManagerDelegate?
    let crashlyticsLogger = SpinCarCrashlyticsLogger.SpinCarLogger
    let bundle = Bundle.main.bundleIdentifier!
    let Common = CommonHelpers.CommonHelper
    var alamofireManager: Alamofire.SessionManager?
    var soundEffectPlayer: SoundEffectPlayer?
    let defaults = UserDefaults.standard
    var uploadProgress: Float = 0.0
    var totalFilesComplete = 0
    var dataID: String?
    
    let errorTitle = NSLocalizedString(
        "Error",
        comment: "Alert title indicating something went wrong"
    )
    
    var errorMessage: String {
        get {
            if self.saveable is SpinMO {
                return NSLocalizedString(
                    "Spin_Error_Message",
                    comment: "Alert title indicating there was an issue uploading the user's WalkAround"
                )
            } else {
                return NSLocalizedString(
                    "Video_Error_Message",
                    comment: "Alert title indicating there was an issue uploading the user's video"
                )
            }
        }
    }
    
    var saveable: SaveableMO?
    var timer: Timer?
    var elapsedTime = 0
    var currentView: ViewMO?
    var isUploadingAll = false
    var totalFileCount = 0
    var assetIndex = 0
    var viewIndex = 0
    
    init(saveable: SaveableMO!, delegate: UploadManagerDelegate, isUploadingAll: Bool) {
        super.init()
// rewrite idletimer
        self.saveable = saveable
        // Setup timer to monitor upload duration and prompt user if a slow network is detected
        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { timer in
            self.elapsedTime += 1
            guard let sizeInBytes = self.saveable?.size else { return }
            // Chose an arbitrary 3Mbps lower threshold => 3 x 10^6 / 2^3 = 375,000 bytes per second.
            if self.elapsedTime > (sizeInBytes / 375000) {
                MixpanelManager.trackEvent("Slow Network < 3Mbps for spin of size: \(sizeInBytes/1000000) MB")
            }
        })
        
        
        self.dataID = saveable.id!
        self.delegate = delegate
        self.isUploadingAll = isUploadingAll
        self.soundEffectPlayer = SoundEffectPlayer()
        let randomString = ProcessInfo.processInfo.globallyUniqueString as NSString
        let configuration = URLSessionConfiguration.background(
            withIdentifier: "\(bundle)-background-session-upload-s3-\(dataID)-\(randomString)"
        )
        configuration.timeoutIntervalForResource = 172800
        configuration.timeoutIntervalForRequest = 300
        self.alamofireManager = Alamofire.SessionManager(configuration: configuration)
        self.totalFileCount = self.saveable?.length ?? 0
        MixpanelManager.timeEvent("Uploaded spin")
        self.uploadViews()
    }
    
    func uploadViews() {
        if let saveable = self.saveable, let views = saveable.views {
            if self.viewIndex > views.count - 1 {
                self.viewIndex = 0
                if self.saveable is SpinMO {
                    self.uploadComplete()
                }
            } else {
                self.currentView = views[self.viewIndex]
                self.uploadAssets()
            }
        }
    }
    
    func uploadAssets() {
        if self.assetIndex > self.currentView!.assets!.count - 1 {
            self.assetIndex = 0
            self.viewIndex += 1
            self.uploadViews()
        } else {
            var signingType = ""
            if let exteriorView = self.currentView as? ExteriorViewMO {
                signingType = "video"
                if exteriorView.exteriorType != nil {
                    signingType = exteriorView.exteriorType == "video" ? "video" : "photo"
                }
                if signingType == "video" {
                    self.uploadGyroInformation()
                }
            }
            if self.currentView is CloseupViewMO {
                signingType = "photo"
            }
            if let interiorView = self.currentView as? InteriorViewMO {
                if interiorView.pano == 1 {
                    signingType = "pano"
                } else {
                    signingType = "photo"
                }
            }
            let orderedAssets = self.currentView!.assets!.sorted(by: { (a1, a2) -> Bool in
                return a1.index!.intValue < a2.index!.intValue
            })
            self.uploadAsset(asset: orderedAssets[self.assetIndex], signingType: signingType)
        }
    }
    
    func uploadGyroInformation() {
        let fileManager =  FileManager.default
        guard let saveable = self.saveable,
        let exteriorView = self.saveable?.getViewOfType(viewType: ExteriorViewMO.self),
        let settings = UserDefaults.standard.value(forKey: "settings") as? [String: Any],
        (settings[SettingsConstants.seamReductionEnabled] as? Bool) == true else {
            return
        }
        
        if let filePath = exteriorView.assets?.first?.basePath?.appendingPathComponent("gyro.json") as NSURL?,
        let path = filePath.path,
        fileManager.fileExists(atPath: path) {
            SpinCarHTTPClient.sharedManager.signJsonUpload(saveable: saveable, jsonInformation: "gyro") { (success, signingResponse) -> Void in
                if success {
                    self.uploadMediaToS3(parameters: signingResponse, localFilePath: filePath, isVideo: false, completionHandler: { (success, errorMessage) -> Void in
                        if !success {
                            self.crashlyticsLogger.log("Failed to upload JSON")
                        }
                    })
                } else {
                    self.crashlyticsLogger.log("Failed to sign JSON")
                }
            }
        }
    }
    
    func uploadAsset(asset: AssetMO, signingType: String) {
        if asset.uploaded == 1 {
            // Already uploaded, so continue to next asset
            self.assetIndex += 1
            self.uploadAssets()
            return
        }
        if let fullURL = asset.fullURL,
        let saveable = self.saveable{
            switch signingType {
            case "video":
                let role = self.saveable?.type ?? ""
                SpinCarHTTPClient.sharedManager.signVideoUpload(saveable: saveable, role: role, completionHandler: { (success, signingResponse) -> Void in
                    if success {
                        self.uploadMediaToS3(parameters: signingResponse, localFilePath: fullURL, completionHandler: { (success, errorMessage) -> Void in
                            if success {
                                asset.uploaded = 1
                                self.assetIndex += 1
                                self.uploadAssets()
                            } else if errorMessage != "cancelled" {
                                self.displayAlert(title: self.errorTitle, description: errorMessage)
                            }
                        })
                    } else {
                        self.displayAlert(title: self.errorTitle, description: self.errorMessage)
//  rewrite                      parentViewController.uploadCancelled(saveable: saveable)
                    }
                })
            case "photo":
                // Interior by default
                var tag: String? = nil
                var photoType = "i"
                var index = self.assetIndex
                if self.currentView is CloseupViewMO {
                    tag = asset.tag
                    photoType = "closeups"
                }
                if self.currentView is ExteriorViewMO {
                    photoType = "ec"
                }
                if self.currentView is InteriorViewMO {
                    index = self.assetIndex
                }
                if let spin = saveable as? SpinMO {
                    SpinCarHTTPClient.sharedManager.signPhotoUploads(spin: spin, index: index, photoType: photoType, closeupTag: tag, completionHandler: { (success, signingResponse) -> Void in
                        if success {
                            self.crashlyticsLogger.log("Successfully signed \(photoType) photo with index %@", varargs: [asset.index ?? "Nil Index -- Investigate" as AnyObject])
                            self.uploadMediaToS3(parameters: signingResponse, localFilePath: fullURL, completionHandler: { (success, errorMessage) -> Void in
                                if success {
                                    asset.uploaded = 1
                                    self.assetIndex += 1
                                    self.uploadAssets()
                                } else if errorMessage != "cancelled" {
                                    self.displayAlert(title: self.errorTitle, description: errorMessage)
                                }
                            })
                        } else {
                            self.displayAlert(title: self.errorTitle, description: self.errorMessage)
//                         rewrite   parentViewController.uploadCancelled(saveable: saveable)
                        }
                    })
                } else {
                    self.displayAlert(title: self.errorTitle, description: self.errorMessage)
//                rewrite    parentViewController.uploadCancelled(saveable: saveable)
                }
            case "pano":
                if let spin = saveable as? SpinMO {
                    SpinCarHTTPClient.sharedManager.signRicohUpload(spin: spin, completionHandler: { (success, signingResponse) -> Void in
                        if success {
                            self.uploadMediaToS3(parameters: signingResponse, localFilePath: fullURL, completionHandler: { (success, errorMessage) -> Void in
                                if success {
                                    asset.uploaded = 1
                                    self.assetIndex += 1
                                    self.uploadAssets()
                                } else if errorMessage != "cancelled" {
                                    self.displayAlert(title: self.errorTitle, description: errorMessage)
                                }
                            })
                        } else {
                            self.displayAlert(title: self.errorTitle, description: self.errorMessage)
//                         rewrite   parentViewController.uploadCancelled(saveable: saveable)
                        }
                    })
                } else {
                    self.displayAlert(title: self.errorTitle, description: self.errorMessage)
//                   rewrite parentViewController.uploadCancelled(saveable: saveable)
                }
            default:
                break
            }
        } else {
            self.displayAlert(title: self.errorTitle, description: self.errorMessage)
        }
    }
    
    func uploadComplete() {
        self.crashlyticsLogger.log("Uploads complete!")
        let properties: [NSObject: AnyObject] = [
            "VIN" as NSObject: self.saveable?.id as AnyObject,
            "Uploading All" as NSObject: self.isUploadingAll as AnyObject,
            "Number of Files Uploaded" as NSObject: self.totalFileCount as AnyObject
        ]
        MixpanelManager.trackEvent("Uploaded spin", properties: properties)
        
        
        
        SpinCarHTTPClient.sharedManager.uploadFinished(saveable: self.saveable!, completionHandler: { (success) -> Void in
            self.soundEffectPlayer?.playSound(.Success)
            self.delegate?.uploadComplete(success, saveable: self.saveable!, hideAlert: false)
        })
    }
    
    func uploadMediaToS3(parameters: [String: AnyObject]?, localFilePath: NSURL!, isVideo: Bool = false, completionHandler: @escaping ((_ success: Bool, _ errorMessage: String?) -> Void)) {
        guard let params = parameters,
        let destinationPath = params["action"] as? String,
        let fields = params["fields"] as? [[String]] else {
            self.crashlyticsLogger.log("Error: invalid parameters in uploadMediaToS3")
            completionHandler(false, nil)
            return
        }
        
        let backgroundTask = BackgroundTaskHelper(logger: self.crashlyticsLogger)
        backgroundTask.registerBackgroundTask()
        var fileSize: Int64 = 0
        
        self.alamofireManager?.upload(
            multipartFormData: { multipartFormData in
            if let mediaData = NSData(contentsOf: localFilePath as URL) {
                for (parameter) in fields {
                    let key = parameter[0] as String
                    let value = parameter[1] as String
                    if key == "key" || key == "Content-Type" {
                        self.crashlyticsLogger.log("PARAMETER: %@ %@", varargs: [key as AnyObject, value as AnyObject])
                    }
                    multipartFormData.append(value.data(using: String.Encoding.utf8)!, withName: key)
                }
                var mimeTypeString = isVideo ? "video/mpeg" : "image/jpeg"
                if localFilePath.pathExtension == ".json" {
                    mimeTypeString = "application/json"
                }
                multipartFormData.append(mediaData as Data, withName: "file", mimeType: mimeTypeString)
            }
        },
            to: destinationPath,
            encodingCompletion: { encodingResult in
            switch encodingResult {
                case .success(let upload, _, _):
                    upload.uploadProgress(closure: { (Progress) in
                        let fileProgress = Float(Progress.completedUnitCount) / Float(Progress.totalUnitCount)
                        let globalProgress = Float(self.totalFilesComplete) / Float(self.totalFileCount)
                        self.uploadProgress = globalProgress + fileProgress * (1 / Float(self.totalFileCount))
                        self.delegate?.progressUpdate(self.uploadProgress, dataID: self.dataID)
                        if fileProgress == 1.0 {
                            self.totalFilesComplete += fileSize != Progress.totalUnitCount ? 1 : 0
                            fileSize = Progress.totalUnitCount
                        }
                        #if DEBUG
                            print("UPLOAD: \(self.uploadProgress)") // Intentionally left as a print and not a log
                        #endif
                    })
                    upload.responseJSON(completionHandler: { response in
                        if response.result.isSuccess {
                            self.crashlyticsLogger.log("UPLOAD RESPONSE: %@", varargs: [response.result.description as AnyObject])
                            /*
                             * Delete Alamofire temp files.
                             * Yes - we have to do this manually https://github.com/Alamofire/Alamofire/issues/1093
                             */
                            let tempDirectoryPath = NSTemporaryDirectory()
                            let dir = URL(fileURLWithPath: tempDirectoryPath, isDirectory:true)
                                .appendingPathComponent("com.alamofire.manager")
                                .appendingPathComponent("multipart.form.data")
                            do {
                                try FileManager.default.removeItem(atPath: dir.path)
                            } catch {}
                            completionHandler(true, nil)
                        } else {
                            var reason = response.result.error.debugDescription
                            if let error = response.result.error {
                                var url_string = ""
                                if let request = response.request {
                                    if let url = request.url {
                                        url_string = ", URL: \(url)"
                                    }
                                }
                                reason = "Error code: \((error as NSError).code), \(error.localizedDescription) \(url_string)"
                            }
                            var didUploadString = ""
                            if self.totalFilesComplete > 0 {
                                didUploadString = NSLocalizedString(
                                    "Did_Upload_String_1",
                                    comment: "(1) Alert message indicating x files out of y uploaded"
                                    ) +
                                    String(self.totalFilesComplete) + NSLocalizedString(
                                        "Did_Upload_String_2",
                                        comment: "(2) Alert message indicating x files out of y uploaded"
                                    ) +
                                    String(self.totalFileCount) + "."
                            }
                            self.crashlyticsLogger.log(didUploadString)
                            
                            if response.result.error?.localizedDescription == "cancelled" {
                                completionHandler(false, "cancelled")
                            } else {
                                self.crashlyticsLogger.log_non_fatal("Error in upload", reason: reason as AnyObject)
                                completionHandler(
                                    false,
                                    NSLocalizedString(
                                        "Upload_Error_Message",
                                        comment: "Alert title indicating some files got uploaded but not all"
                                        ) + didUploadString
                                )
                            }
                        }
                        backgroundTask.endBackgroundTask()
                    })
                case .failure(let encodingError):
                    backgroundTask.endBackgroundTask()
                    self.crashlyticsLogger.log_non_fatal("Encoding Failure", reason: encodingError as AnyObject)
                    completionHandler(
                        false,
                        NSLocalizedString(
                            "Encoding_Error_Message",
                            comment: "Alert title indicating there was an encoding error with the upload"
                        )
                    )
            }
        })
    }
    
    func cancelCurrentRequest() {
        self.crashlyticsLogger.log("Canceling current NSURL session")
        self.alamofireManager?.session.getTasksWithCompletionHandler({ (dataTasks, uploadTasks, downloadTasks) in
            // We don't allow concurrent uploading, so our Alamofire session will only have 1 upload task in it
            if let task = uploadTasks.first,
            let saveable = self.saveable {
                task.cancel()
                self.delegate?.uploadCancelled(saveable: saveable)
            }
        })
    }
    
    func displayAlert(title: String, description: String?) {
        let alertController = UIAlertController(title: title, message: description, preferredStyle: .alert)
        alertController.addAction(
            UIAlertAction(
                title: NSLocalizedString(
                    "OK",
                    comment: "Alert action indicating user accepts the displayed alert"
                ),
                style: .default,
                handler: nil
            )
        )

        self.delegate?.uploadComplete(false, saveable: self.saveable!, hideAlert: true)
//        rewrite
    }
    
    func displaySlowNetworkAlert() {
        if let lastAlertDate = UserDefaults.standard.value(forKey: "slowNetworkDetectedDate") as? Date {
            guard Date().timeIntervalSince(lastAlertDate) > 24.0 * 3600.0 else { return }
        } else {
            UserDefaults.standard.setValue(Date(), forKey: "slowNetworkDetectedDate")
        }
        let alertController = UIAlertController(
            title: NSLocalizedString("Slow_Network_Title", comment: "Title for slow network alert."),
            message: NSLocalizedString("Slow_Network_Message", comment: "Message informing user of slow network conditions."),
            preferredStyle: .alert
        )
        alertController.addAction(
            UIAlertAction(
                title: NSLocalizedString(
                    "OK",
                    comment: "Alert action indicating user accepts the displayed alert"
                ),
                style: .default,
                handler: nil
            )
        )
//        rewrite
//        self.parentViewController?.present(alertController, animated: true, completion: nil)
    }
}
