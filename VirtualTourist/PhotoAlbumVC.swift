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
    
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    var photoToDelete: Photo?
    
    var locationHasStoredPhotos = false
    
    let maxPhotos = 18
    var maxFlickrPhotoPageNumber = 1
    var targetFlickrPhotoPage = 1
    
    // MARK: - Outlets
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var collectionView: UICollectionView!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* Configure the map */
        var mapRegion = MKCoordinateRegion()
        var mapSpan = MKCoordinateSpan()
        mapSpan.latitudeDelta = 0.02
        mapSpan.longitudeDelta = 0.02
        mapRegion.span = mapSpan
        mapRegion.center = mapAnnotation.coordinate
        
        mapView.zoomEnabled = false
        mapView.scrollEnabled = false
        mapView.pitchEnabled = false
        mapView.rotateEnabled = false
        mapView.userInteractionEnabled = false
        mapView.region = mapRegion
        
        mapView.addAnnotation(mapAnnotation)
        
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
        
        print("\nHere is the (custom) map annotation: ")
        print(self.mapAnnotation)
        print(self.mapAnnotation.title)
        print(self.mapAnnotation.pin)
        print("Here is the latitude and longitude, respectively: ")
        print(self.mapAnnotation.pin.latitude)
        print(self.mapAnnotation.pin.longitude)
        
        // For debugging only ---
        let flotsam = fetchedResultsController.fetchedObjects
        print("\nHere is flotsam: ")
        print(flotsam)
        print("Here is the number of photos that were returnded by the fetched results controller: \(flotsam?.count)")
        print(fetchedResultsController.sections?.count)
        // ---------------------------------------------
        
        if let totalStoredPhotos = fetchedResultsController.fetchedObjects?.count {
            if totalStoredPhotos > 0 {
                locationHasStoredPhotos = true
            }
        }
        
        if !locationHasStoredPhotos {
            
            print("New photos need to be downloaded from flickr")
            
            /*
            loadNewImages(targetFlickrPhotoPage) { (newPhotoArray, error, errorDesc) in
                
                print("(loadNewImages closure) Here is the maximum page number for the flickr data: \(self.maxFlickrPhotoPageNumber)")
                
                if !error {
                    
                    print("Here is newPhotoArray:")
                    print(newPhotoArray)
                    
                    /*
                     self.totalAvailableNewPhotos = (newPhotoArray?.count)!
                     
                     self.newTouristPhotos.removeAll()
                     self.newTouristPhotos = newPhotoArray!
                     
                     performUIUpdatesOnMain() {
                     self.flickrCollectionView.reloadData()
                     } */
                }
            }*/
            
            
            // Get images according to location
            downloadNewImages(targetFlickrPhotoPage, maxPhotos: self.maxPhotos) { (newPhotoArray, error, errorDesc) in
                
                if !error {
                    print("\n\n\n(downloadNewImages closure)Here is newPhotoArray:")
                    print(newPhotoArray)
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    func loadNewImages(targetPage: Int, completionHandlerForloadNewImages: (newPhotoArray: [NewPhoto]?, error: Bool, errorDesc: String?) -> Void) {
        
        FlickrClient.sharedInstance().getRandomSubsetPhotoDataArrayFromFlickr(targetFlickrPhotoPage, maxPhotos: maxPhotos) { (newPhotoArray, pageTotal, error, errorDesc) in
            
            print("\n\n (getRandomSubsetPhotoDataArrayFromFlickr closure) Here is newPhotoArray: ")
            //print(newPhotoArray)
            //print(newPhotoArray?.count)
            print("muted")
            
            if !error {
                
                print("Here is the page total: ")
                print(pageTotal)
                
                if let newMaxFlickrPhotoPages = pageTotal {
                    print(newMaxFlickrPhotoPages)
                    self.maxFlickrPhotoPageNumber = newMaxFlickrPhotoPages
                }
                
                completionHandlerForloadNewImages(newPhotoArray: newPhotoArray, error: false, errorDesc: nil)
                
            } else {
                completionHandlerForloadNewImages(newPhotoArray: nil, error: true, errorDesc: "Unable to return new images")
            }
            
        }
        
    }
    
    func downloadNewImages(targetPageNumber: Int, maxPhotos: Int, completionHandlerForDownloadNewImages: (newPhotoArray: [NewPhoto]?, error: Bool, errorDesc: String?) -> Void) {
        
        print("\ndownloadNewImages called")
        
        if let longitudeForFlickrPhotos = mapAnnotation.pin.longitude, latitudeForFlickrPhotos = mapAnnotation.pin.latitude {
            
            let boundingBoxCorners = FlickrClient.sharedInstance().boundingBoxAsString(longitudeForFlickrPhotos, latitude: latitudeForFlickrPhotos)
            
            print("Here are the bounding box corners: ")
            print(boundingBoxCorners)
            
            FlickrClient.sharedInstance().getNewPhotoArrayWithConstraints(boundingBoxCorners, targetPageNumber: targetPageNumber, maxPhotos: maxPhotos) { (newPhotoArray, pageTotal, error, errorDesc) in
                
                if !error {
                    
                    if let newMaxFlickrPhotoPages = pageTotal {
                        print(newMaxFlickrPhotoPages)
                        self.maxFlickrPhotoPageNumber = newMaxFlickrPhotoPages
                    }
                    
                    completionHandlerForDownloadNewImages(newPhotoArray: newPhotoArray, error: false, errorDesc: nil)
                } else {
                    completionHandlerForDownloadNewImages(newPhotoArray: nil, error: true, errorDesc: "Unable to return new images")
                }
            }
        }
        
    }
    
    // MARK: - NSFetchedResultsController
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = []
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
}


// MARK: - Delegate methods for the collection view

extension PhotoAlbumVC: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        
        // Filler code
        return 1
        
        // TODO: Implement the fetched results controller
        
        // Use the Fetched Results Controller
        //print("in numberOfSectionsInCollectionView()")
        //return self.fetchedResultsController.sections!.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        // Filler code
        return 1
        
        // TODO: Implement the fetched results controller
        // Use the Fetched Results Controller
        /*
         print("in collectionView(_:numberOfItemsInSection)")
         let sectionInfo = fetchedResultsController.sections![section]
         print("number Of Cells: \(sectionInfo.numberOfObjects)")
         return sectionInfo.numberOfObjects */
    }
    
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        print("in collectionView(_:cellForItemAtIndexPath)")
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("TouristPhotoCell", forIndexPath: indexPath) as UICollectionViewCell
        
        // let cell = collectionView.dequeueReusableCellWithReuseIdentifier("CollectionViewCell", forIndexPath: indexPath) as! DeleteCellsCollectionViewCell
        // cell.imageView.backgroundColor = UIColor.blueColor()
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        print("in collectionView(_:didSelectItemAtIndexPath)")
        
        print("Cell at index path \(indexPath) was tapped ")
        
        
    }
    
}


// MARK: - Delegate methods for the fetched results controller

extension PhotoAlbumVC: NSFetchedResultsControllerDelegate {
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        /* Detect the type of change that has triggered the event */
        
        switch type {
            
        case .Insert:
            print("NSFetchedResultsChangeType.Insert detected")
            let newIndexPathAdjusted = NSIndexPath(forItem: newIndexPath!.item, inSection: 0)
            insertedIndexPaths.append(newIndexPathAdjusted)
        case .Delete:
            print("NSFetchedResultsChangeType.Delete detected")
            let indexPathAdjusted = NSIndexPath(forItem: indexPath!.item, inSection: 0)
            deletedIndexPaths.append(indexPathAdjusted)
        case .Update:
            print("NSFetchedResultsChangeType.Update detected")
            let indexPathAdjusted = NSIndexPath(forItem: indexPath!.item, inSection: 0)
            updatedIndexPaths.append(indexPathAdjusted)
        case .Move:
            print("NSFetchedResultsChangeType.Move detected")
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
            }, completion: { (success) in
                
                print("The completion handler for controllerDidChangeContent was called")
                print("Here is 'success':  ")
                print(success)
            }
        )
        
    }
}