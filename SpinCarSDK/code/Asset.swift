//
//  Asset.swift
//  SpinCarSDK
//
//  Created by Archil Kuprashvili on 8/31/18.
//  Copyright © 2018 Archil Kuprashvili. All rights reserved.
//

import Foundation
public enum AssetType{
    case EXTERIOR
    case INTERIOR
    case CLOSEUP
}
open class Asset{
    
    private let dc = DataController.sharedInstance
    private var type: AssetType = .EXTERIOR
    private var index: Int!
    private var localPath: String!
    private var thumbPath: String!
    private var s3path: String?
    private var etag: String!
    private var mimeType: String!
    private var isvideo: Bool = false
    private var ispanoramic: Bool = false
    private var ishotspot: Bool = false
    private var closeupTag: String!
    internal var assetMo: AssetMO?
    public init(type: AssetType, localPath: String, thumbPath: String, etag: String, mimeType: String, isVideo: Bool, isPanoramic: Bool, isHotspot:Bool, closeupTag:String = "") {
        self.type = type
        self.localPath = localPath
        self.thumbPath = thumbPath
//        self.s3path = s3path
        self.etag = etag
        self.mimeType = mimeType
        self.isvideo = isVideo
        self.ispanoramic = isPanoramic
        self.ishotspot = isHotspot
        self.closeupTag = closeupTag
        initAssetMo()
    }
    private func initAssetMo(){
        guard let asset = self.dc.newEntity(entityName: "Asset") as? AssetMO else {
            fatalError("cannot create Asset entity")
            return
        }
        assetMo = asset
        assetMo?.filePath = localPath
        assetMo?.thumbnailPath = thumbPath
        assetMo?.index = NSNumber(value: index)
        assetMo?.tag = closeupTag
        assetMo?.uploaded = 0
        assetMo?.etag = etag
        
    }
////Get
    public func getType() -> AssetType{
        return type
    }
    
    public func getIndex() -> Int{
        return index
    }
    
    public func getLocalPath() -> String{
        return localPath
    }
    
    public func getThumbPath() -> String{
        return thumbPath
    }
    
    public func getS3path() -> String?{
        return s3path
    }
    
    public func getEtag() -> String{
        return etag
    }
    
    public func getMimeType() -> String{
        return mimeType
    }
    
    public func isVideo() -> Bool{
        return isvideo
    }
    
    public func isPanoramic() -> Bool{
        return ispanoramic
    }
    
    public func isHotspot() -> Bool{
        return ishotspot
    }
    
    public func getCloseupTag() -> String{
        return closeupTag
    }
    
////Set
    public func setType(type: AssetType){
        self.type = type
    }
    
    public func setIndex(index: Int){
        self.index = index
        assetMo?.index = NSNumber(value: index)
    }
    
    public func setLocalPath(localPath: String){
        self.localPath = localPath
        assetMo?.filePath = localPath
    }
    
    public func setThumbPath(thumbPath: String){
        self.thumbPath = thumbPath
        assetMo?.thumbnailPath = thumbPath
    }
    
    public func setS3path(s3path: String){
        self.s3path = s3path
    }
    
    public func setEtag(etag: String){
        self.etag = etag
        assetMo?.etag = etag
    }
 
    public func setMimeType(mimeType: String){
        self.mimeType = mimeType
    }
    
    public func setIsVideo(isVideo: Bool){
        self.isvideo = isVideo
    }
    
    public func setIsPanoramic(isPanoramic: Bool){
        self.ispanoramic = isPanoramic
    }
    
    public func setIsHotspot(isHorspot: Bool){
        self.ishotspot = isHorspot
    }
    
    public func setCloseupTag(closeupTag: String){
        self.closeupTag = closeupTag
        assetMo?.tag = closeupTag
    }
}








