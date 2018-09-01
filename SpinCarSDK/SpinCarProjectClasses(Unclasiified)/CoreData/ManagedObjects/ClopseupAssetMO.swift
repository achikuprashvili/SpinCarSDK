class CloseupAssetMO: AssetMO {
    @NSManaged var isHotspot: NSNumber?
    @NSManaged var isMisc: NSNumber?
    @NSManaged var closeupView: CloseupViewMO?
    
    override var basePath: NSURL? {
        if let view = self.closeupView, let viewPath = view.fullURL {
            return viewPath
        }
        return nil
    }
}
