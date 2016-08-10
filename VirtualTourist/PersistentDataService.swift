//
//  PersistentDataService.swift
//  VirtualTourist
//
//  Created by Daniel J Janiak on 7/19/16.
//  Copyright © 2016 Daniel J Janiak. All rights reserved.
//

import Foundation
import MapKit
import CoreData

public class PersistentDataService {
    
    // MARK: - Properties
    public var managedObjectContext: NSManagedObjectContext!
    
    public init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
    }
    
    // MARK: - Helpers
    
    func getPinEntities() -> [Pin] {
        
        let request = NSFetchRequest(entityName: "Pin")
        
        let results: [Pin]
        
        do {
            results = try managedObjectContext.executeFetchRequest(request) as! [Pin]
        }
        catch {
            fatalError("Error getting pins")
        }
        
        return results
        
    }
    
    func removePinEntity(entityToRemove: Pin) {
        
        //print("\nremovePinEntity called.  Here is the current thread: \(NSThread.currentThread())")
        //print(entityToRemove)
        
        managedObjectContext.deleteObject(entityToRemove)
        
    }
    
    func deleteAllPhotoEntities() {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        
        do {
            let results = try managedObjectContext.executeFetchRequest(fetchRequest) as! [Photo]
            for item in results {
                managedObjectContext.deleteObject(item)
            }
            
            let photosCount = managedObjectContext.countForFetchRequest(fetchRequest, error: nil)
            print("Total photos in the data store after clean up: \(photosCount)")
        }
        catch {
            fatalError("Error deleting persisted Photo entities")
        }
    }
    
}
