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
        // TODO: Implement this function
        print("\nremovePinEntity called ")
        print(entityToRemove)
        
        managedObjectContext.deleteObject(entityToRemove)
        
    }
    
}
