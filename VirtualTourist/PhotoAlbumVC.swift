//
//  PhotoAlbumVC.swift
//  VirtualTourist
//
//  Created by Daniel J Janiak on 7/19/16.
//  Copyright © 2016 Daniel J Janiak. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumVC: UIViewController {
    
    // MARK: - Properties
    
    var sharedContext = CoreDataStack.sharedInstance().managedObjectContext
    
    var mapAnnotation: CustomPinAnnotation!
    
    let defaultCenter = CLLocationCoordinate2D(latitude: 37.13283999999998, longitude: -95.785579999999996)
    let defaultSpan = MKCoordinateSpan(latitudeDelta: 72.355996899647238, longitudeDelta: 61.276016959789544)
    
    var newTouristPhotos: [NewPhoto] = []
    var setOfPhotosToSave: Set<NSData> = []
    
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    var photoToDelete: Photo?
    
    var locationHasStoredPhotos = false
    
    let maxPhotos = 18
    var maxFlickrPhotoPageNumber = 1
    var targetFlickrPhotoPage = 1
    
    var displayedPhotosCount: Int!
    
    // MARK: - Outlets
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet var newCollectionButton: UIButton!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Force the image download from flickr to occur
        //print("Removing all photo entities ... ")
        //deleteAllPhotoEntities()
        
        /* Configure the map */
        var mapRegion = MKCoordinateRegion()
        var mapSpan = MKCoordinateSpan()
        mapSpan.latitudeDelta = 0.02
        mapSpan.longitudeDelta = 0.02
        
        if mapAnnotation.pin != nil {
            mapRegion.span = mapSpan
            mapRegion.center = mapAnnotation.coordinate
            mapView.addAnnotation(mapAnnotation)
        } else {
            mapRegion.span = defaultSpan
            mapRegion.center = defaultCenter
        }
        
        mapView.zoomEnabled = false
        mapView.scrollEnabled = false
        mapView.pitchEnabled = false
        mapView.rotateEnabled = false
        mapView.userInteractionEnabled = false
        mapView.region = mapRegion
        
        
        
        /* Configure the collection view */
        collectionView.delegate = self
        collectionView.dataSource = self
        
        /* Start the fetched results controller */
        var error: NSError?
        do {
            try fetchedResultsController.performFetch()
        } catch let error1 as NSError {
            error = error1
        }
        
        if let error = error {
            print("Error performing initial fetch: \(error)")
        }
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        displayedPhotosCount = 0
        newCollectionButton.alpha = 0.5
        newCollectionButton.enabled = false
        
        /* Configure the collection view cell size */
        let space: CGFloat = 1.0
        let dimension = (view.frame.size.width - (2*space)) / 3.0
        
        flowLayout.minimumInteritemSpacing = 0.0
        flowLayout.itemSize = CGSizeMake(dimension, dimension)
        
        if let totalStoredPhotos = fetchedResultsController.fetchedObjects?.count {
            if totalStoredPhotos > 0 {
                locationHasStoredPhotos = true
                self.newCollectionButton.alpha = 1.0
                self.newCollectionButton.enabled = true
            }
        }
        
        if !locationHasStoredPhotos && (mapAnnotation.pin != nil) {
            print("here is the map annotation: ")
            print(mapAnnotation)
            print("About to download new images")
            downloadNewImages(targetFlickrPhotoPage, maxPhotos: self.maxPhotos) { (newPhotoArray, error, errorDesc) in
                
                if !error {
                    print("New images have been downloaded")
                    if !self.newTouristPhotos.isEmpty {
                        self.newTouristPhotos.removeAll()
                    }
                    
                    self.newTouristPhotos = newPhotoArray!
                    
                    self.sharedContext.performBlock() {
                        
                        for item in self.newTouristPhotos {
                            let newPhotoEntity = NSEntityDescription.insertNewObjectForEntityForName("Photo", inManagedObjectContext: self.sharedContext) as! Photo
                            newPhotoEntity.pin = self.mapAnnotation.pin
                            newPhotoEntity.id = item.id! as NSNumber
                        }
                        CoreDataStack.sharedInstance().saveContext()
                        
                    }

                }
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        /* Remove Photo entities that have no image, e.g. if photo data did not finish downloading before the user moves to a different view */
        
        if !self.newTouristPhotos.isEmpty {
            self.newTouristPhotos.removeAll()
        }
        
        sharedContext.performBlock() {
            for item in self.fetchedResultsController.fetchedObjects as! [Photo] {
                
                if item.image == nil {
                    self.sharedContext.deleteObject(item)
                }
            }
            
            CoreDataStack.sharedInstance().saveContext()
        }
        
    }
    
    // MARK: - Helpers
    
    /*
    func loadNewImages(targetPage: Int, completionHandlerForloadNewImages: (newPhotoArray: [NewPhoto]?, error: Bool, errorDesc: String?) -> Void) {
        
        FlickrClient.sharedInstance().getRandomSubsetPhotoDataArrayFromFlickr(targetFlickrPhotoPage, maxPhotos: maxPhotos) { (newPhotoArray, pageTotal, error, errorDesc) in
            
            if !error {
                
                if let newMaxFlickrPhotoPages = pageTotal {
                    self.maxFlickrPhotoPageNumber = newMaxFlickrPhotoPages
                }
                
                completionHandlerForloadNewImages(newPhotoArray: newPhotoArray, error: false, errorDesc: nil)
                
            } else {
                completionHandlerForloadNewImages(newPhotoArray: nil, error: true, errorDesc: "Unable to return new images")
            }
            
        }
        
    } */
    
    func downloadNewImages(targetPageNumber: Int, maxPhotos: Int, completionHandlerForDownloadNewImages: (newPhotoArray: [NewPhoto]?, error: Bool, errorDesc: String?) -> Void) {
        print("downloadNewImages has been called")
        if let longitudeForFlickrPhotos = mapAnnotation.pin!.longitude, latitudeForFlickrPhotos = mapAnnotation.pin!.latitude {
            
            let boundingBoxCorners = FlickrClient.sharedInstance().boundingBoxAsString(longitudeForFlickrPhotos, latitude: latitudeForFlickrPhotos)
            
            FlickrClient.sharedInstance().getNewPhotoArrayWithConstraints(boundingBoxCorners, targetPageNumber: targetPageNumber, maxPhotos: maxPhotos) { (newPhotoArray, pageTotal, error, errorDesc) in
                
                if !error {
                    
                    /* Update the page number of the last page of photo results in case it has changed since the first call to flickr */
                    if let newMaxFlickrPhotoPages = pageTotal {
                        //print("Here is the (updated) maximum number of photo pages")
                        //print(newMaxFlickrPhotoPages)
                        self.maxFlickrPhotoPageNumber = newMaxFlickrPhotoPages
                    }
                    
                    completionHandlerForDownloadNewImages(newPhotoArray: newPhotoArray, error: false, errorDesc: nil)
                } else {
                    completionHandlerForDownloadNewImages(newPhotoArray: nil, error: true, errorDesc: "Unable to return new images")
                }
            }
        }
        
    }
    
    func deleteAllPhotoEntities() {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        
        do {
            
            let allPhotos = try sharedContext.executeFetchRequest(fetchRequest) as! [Photo]
            
            for item in allPhotos {
                sharedContext.deleteObject(item)
            }
            
        } catch {
            fatalError("Unable to delete Photo entities")
        }
    }
    
    func savePhotosToDataStore(newPhotoDataSet: Set<NSData>) {
        
        for item in newPhotoDataSet {
            let photoEntityToSave = NSEntityDescription.insertNewObjectForEntityForName("Photo", inManagedObjectContext: sharedContext) as! Photo
            photoEntityToSave.image = item
            photoEntityToSave.pin = mapAnnotation.pin
        }
        
        CoreDataStack.sharedInstance().saveContext()
    }
    
    // MARK: - Actions
    
    @IBAction func newCollectionTapped(sender: AnyObject) {
        
        newCollectionButton.alpha = 0.5
        newCollectionButton.enabled = false
        displayedPhotosCount = 0
        
        print("\nThe New Collection button was tapped")
        print("The index for the last page of photos is: \(maxFlickrPhotoPageNumber)")
        print("The target photo page number is: \(targetFlickrPhotoPage)")
        
        if targetFlickrPhotoPage < maxFlickrPhotoPageNumber {
            targetFlickrPhotoPage = targetFlickrPhotoPage + 1
        } else {
            targetFlickrPhotoPage = 1
        }
        
        /* Remove persisted Photo entities, if any */
        if let totalStoredPhotos = fetchedResultsController.fetchedObjects?.count {
            
            if totalStoredPhotos > 0 {
                self.sharedContext.performBlock() {
                    for item in self.fetchedResultsController.fetchedObjects as! [Photo] {
                        self.sharedContext.deleteObject(item)
                    }
                }
                
                CoreDataStack.sharedInstance().saveContext()
            }
        }
        
        downloadNewImages(targetFlickrPhotoPage, maxPhotos: self.maxPhotos) { (newPhotoArray, error, errorDesc) in
            
            if !error && self.mapAnnotation.pin != nil {
                //print("\n\n\n(downloadNewImages closure)Here is newPhotoArray:")
                //print(newPhotoArray)
                
                if !self.newTouristPhotos.isEmpty {
                    self.newTouristPhotos.removeAll()
                }
                
                self.newTouristPhotos = newPhotoArray!
                
                self.sharedContext.performBlock() {
                    
                    for item in self.newTouristPhotos {
                        let newPhotoEntity = NSEntityDescription.insertNewObjectForEntityForName("Photo", inManagedObjectContext: self.sharedContext) as! Photo
                        newPhotoEntity.pin = self.mapAnnotation.pin
                        newPhotoEntity.id = item.id! as NSNumber
                    }
                    CoreDataStack.sharedInstance().saveContext()
                    
                }
            }
        }
    }
    
    
    // MARK: - NSFetchedResultsController
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        let sortByID = NSSortDescriptor(key: "id", ascending: true)
        fetchRequest.sortDescriptors = [sortByID]
        fetchRequest.predicate = NSPredicate(format: "pin = %@", self.mapAnnotation.pin!)
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
}


// MARK: - Delegate methods for the collection view

extension PhotoAlbumVC: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        
        return self.fetchedResultsController.sections!.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {                
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("TouristPhotoCell", forIndexPath: indexPath) as! TouristPhotoCell
        cell.touristPhotoCellActivityIndicator.hidden = false
        cell.touristPhotoCellActivityIndicator.startAnimating()
        cell.touristPhotoCellImageView.backgroundColor = UIColor.darkGrayColor() //UIColor.blueColor()
        cell.touristPhotoCellImageView.image = nil
        
        
        let photoFromfetchedResultsController = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        /* When the photo entity does not have photo data, download the image from flickr */
        if photoFromfetchedResultsController.image == nil {
            
            guard !newTouristPhotos.isEmpty else {
                return cell
            }
            
            let newPhotoIndex = newTouristPhotos.indexOf { $0.id == photoFromfetchedResultsController.id }
            
            if newPhotoIndex == nil {
                print("No photo index found!***")
            }
            
            guard newPhotoIndex != nil else {
                return cell
            }
            
            FlickrClient.sharedInstance().returnImageFromFlickrByURL(newTouristPhotos[newPhotoIndex!].url!) { (imageData, error, errorDesc) in
                
                if !error {
                    
                    if let cellImage = UIImage(data: imageData!) {
                        
                        performUIUpdatesOnMain(){
                            cell.touristPhotoCellImageView.image = cellImage
                            self.displayedPhotosCount = self.displayedPhotosCount + 1
                            
                            if self.displayedPhotosCount >= self.maxPhotos {
                                self.newCollectionButton.alpha = 1.0
                                self.newCollectionButton.enabled = true
                            }
                        }
                        
                        self.setOfPhotosToSave.insert(imageData!)
                        
                        self.sharedContext.performBlock() {
                            
                            /* Don't try to mutate an object if it has been removed from the context */
                            let currentFetchedObjects = self.fetchedResultsController.fetchedObjects as! [Photo]
                            if currentFetchedObjects.contains(photoFromfetchedResultsController) {
                                
                                photoFromfetchedResultsController.image = imageData
                                
                                CoreDataStack.sharedInstance().saveContext()
                            }
                            
                        }
                        
                    }
                    
                }
            }
        }
        
        // print("(cellForItemAtIndexPath) The number of photos to be saved is: ")
        // print(setOfPhotosToSave.count)
        
        
        if let image = photoFromfetchedResultsController.image {
            let imageUIImage = UIImage(data: image)
            performUIUpdatesOnMain() {
                cell.touristPhotoCellActivityIndicator.hidden = true
                cell.touristPhotoCellActivityIndicator.stopAnimating()
                cell.touristPhotoCellImageView.image = imageUIImage
            }
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        photoToDelete = fetchedResultsController.objectAtIndexPath(indexPath) as? Photo
        
        if photoToDelete != nil {
            
            self.sharedContext.deleteObject(photoToDelete!)
            
            CoreDataStack.sharedInstance().saveContext()
            
        }
    }
    
}


// MARK: - Delegate methods for the fetched results controller

extension PhotoAlbumVC: NSFetchedResultsControllerDelegate {
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        /* Detect the type of change that has triggered the event */        
        switch type {
            
        case .Insert:
            // print("NSFetchedResultsChangeType.Insert detected")
            let newIndexPathAdjusted = NSIndexPath(forItem: newIndexPath!.item, inSection: 0)
            insertedIndexPaths.append(newIndexPathAdjusted)
        case .Delete:
            // print("NSFetchedResultsChangeType.Delete detected")
            let indexPathAdjusted = NSIndexPath(forItem: indexPath!.item, inSection: 0)
            deletedIndexPaths.append(indexPathAdjusted)
        case .Update:
            // print("NSFetchedResultsChangeType.Update detected")
            let indexPathAdjusted = NSIndexPath(forItem: indexPath!.item, inSection: 0)
            updatedIndexPaths.append(indexPathAdjusted)
        case .Move:
            // print("NSFetchedResultsChangeType.Move detected")
            fallthrough
        default:
            break
        }
    }
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        self.collectionView.performBatchUpdates( { () -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            }, completion: nil //{ (success) in
                
                // print("The completion handler for controllerDidChangeContent was called")
                // print("Here is 'success':  ")
                // print(success)
            //}
        )
        
    }
}