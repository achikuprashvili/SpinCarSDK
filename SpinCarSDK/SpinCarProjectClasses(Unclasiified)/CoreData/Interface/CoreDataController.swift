//
//  DataController.swift
//  SpinCar
//  Copyright © 2016 SpinCar. All rights reserved.
//  Based on https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/CoreData/InitializingtheCoreDataStack.html
//

import UIKit
import CoreData


class DataController: NSObject {
    let crashlyticsLogger = SpinCarCrashlyticsLogger.SpinCarLogger
    var managedObjectContext: NSManagedObjectContext
    static let sharedInstance = DataController()

    override init () {
        
        guard let modelURL = Bundle(for: type(of: self)).url(forResource: "SpinCarModels", withExtension:"momd") else {
            // This should only happen if this file doesn't exist in the project. 
            fatalError("Error loading model from bundle")
        }
        // Note: Can't call self.crashlyticsLogger because init() hasn't finished yet!
        SpinCarCrashlyticsLogger.SpinCarLogger.log("Model URL: \(modelURL)")
        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            // This should only happen if this file exists yet is not a Managed Object Model.
            fatalError("Error initializing mom")
        }
        self.managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)
        self.managedObjectContext.persistentStoreCoordinator = psc

//        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).sync {
            let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let docURL = urls[urls.endIndex-1]
            // Keep track of previous if migration is warranted.
            let storeURL = docURL.appendingPathComponent("SpinCarDataModel20170425.sqlite")
            
            // These options are necessary to have Core Data automatically perform a lightweight migration, when the data model changes minimally
            let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
            do {
                try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options)
                
                    UserDefaults.standard.set(1, forKey: "finishedMigration")
                
            } catch {
                SpinCarCrashlyticsLogger.SpinCarLogger.log_non_fatal("Failed to migrate store", reason: "\(error)" as AnyObject)
            }
//        }
        super.init()
        NotificationCenter.default.addObserver(
            self, selector: #selector(DataController.contextDidSaveContext(_:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: nil
        )
    }

    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        super.init()
        NotificationCenter.default.addObserver(
            self, selector: #selector(DataController.contextDidSaveContext(_:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: nil
        )
    }

    @objc func contextDidSaveContext(_ notification: NSNotification) {
        self.managedObjectContext.perform {
            self.managedObjectContext.mergeChanges(fromContextDidSave: notification as Notification)
        }
    }

    func saveContext() -> Bool {
        if !self.managedObjectContext.hasChanges {
            return true
        }
        do {
            try self.managedObjectContext.save()
            return true
        } catch {
            self.crashlyticsLogger.log_non_fatal("Failed to save managed object context", reason: "\(error)" as AnyObject)
            return false
        }
    }

    func rollback() {
        if self.managedObjectContext.hasChanges {
            self.managedObjectContext.rollback()
        }
    }

    func newEntity(entityName: String) -> NSManagedObject {
        // Creates a new entity, for convenience.
        // No guarantee of persistence, call saveContext() where appropriate, but not here.
        return NSEntityDescription.insertNewObject(forEntityName: entityName, into: self.managedObjectContext)
    }

    func fetch(entityName: String) -> [NSManagedObject] {
        return self.fetch(entityName: entityName, predicate: nil)
    }

    func fetch(entityName: String, predicate: NSPredicate?) -> [NSManagedObject] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        self.crashlyticsLogger.log("Attempting to fetch \(entityName)")
        if let predicate = predicate {
            self.crashlyticsLogger.log("Using predicate \(predicate.debugDescription)")
            fetchRequest.predicate = predicate
        }
        do {
            guard let fetch = try self.managedObjectContext.fetch(fetchRequest) as? [NSManagedObject] else { return [] }
            self.crashlyticsLogger.log("Fetched \(fetch.count) of type \(entityName)")
            return fetch
        } catch {
            self.crashlyticsLogger.log_non_fatal("Failed to execute fetch on managed object context", reason: "\(error)" as AnyObject)
            return []
        }
    }

    func delete(mObjects: [NSManagedObject]) {
        let fileManager = FileManager.default
        for mObject in mObjects {
            if let asset = mObject as? AssetMO, let assetPath = asset.fullURL?.path {
                do {
                    try fileManager.removeItem(atPath: assetPath)
                } catch {
                    self.crashlyticsLogger.log("Failed to delete media for managed object")
                }
            }
            if let spin = mObject as? SpinMO,
            let path = spin.getDirectory().path {
                // Delete all json files, and directories
                let enumerator = fileManager.enumerator(atPath: path)!
                while let element = enumerator.nextObject() as? String {
                    do {
                        if let toDelete = spin.getDirectory().appendingPathComponent(element) {
                            try fileManager.removeItem(at: toDelete)
                        }
                    }
                    catch let error as NSError {
                        self.crashlyticsLogger.log("\(spin.id ?? "nil") delete failed with error: %@", varargs: [error.localizedDescription as AnyObject])
                    }
                }
                // Delete spin folder last
                do {
                    try fileManager.removeItem(at: spin.getDirectory() as URL)
                }
                catch let error as NSError {
                    self.crashlyticsLogger.log("\(spin.id ?? "nil") delete failed with error: %@", varargs: [error.localizedDescription as AnyObject])
                }
            }
            self.managedObjectContext.delete(mObject)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        self.crashlyticsLogger.log("Deinitializing Core Data Controller \(self.debugDescription)")
    }
}
