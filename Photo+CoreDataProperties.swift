//
//  Photo+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Daniel J Janiak on 8/7/16.
//  Copyright © 2016 Daniel J Janiak. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Photo {

    @NSManaged var image: NSData?
    @NSManaged var id: NSNumber?
    @NSManaged var pin: Pin?

}
