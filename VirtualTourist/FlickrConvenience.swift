//
//  FlickrConvenience.swift
//  VirtualTourist
//
//  Created by Daniel J Janiak on 8/4/16.
//  Copyright © 2016 Daniel J Janiak. All rights reserved.
//

import Foundation
import UIKit
import MapKit

extension FlickrClient {
    
    func getNewPhotoArrayWithConstraints(locationParameterKey: String, targetPageNumber: Int, maxPhotos: Int, completionHandlerForGetNewPhotoArrayWithConstraints: (newPhotoArray: [NewPhoto]?, pageTotal:Int?, error: Bool, errorDesc: String?) -> Void) {
        
        print("\ngetNewPhotoArrayWithConstraints called")
        
        // Set method parameters
        let methodParameters: [String: String!] = [
            FlickrClient.Constants.FlickrParameterKeys.Method: FlickrClient.Constants.FlickrParameterValues.SearchMethod,
            FlickrClient.Constants.FlickrParameterKeys.APIKey: FlickrClient.Constants.FlickrParameterValues.APIKey,
            FlickrClient.Constants.FlickrParameterKeys.SafeSearch: FlickrClient.Constants.FlickrParameterValues.UseSafeSearch,
            FlickrClient.Constants.FlickrParameterKeys.Extras: FlickrClient.Constants.FlickrParameterValues.MediumURL,
            FlickrClient.Constants.FlickrParameterKeys.Format: FlickrClient.Constants.FlickrParameterValues.ResponseFormat,
            FlickrClient.Constants.FlickrParameterKeys.NoJSONCallback: FlickrClient.Constants.FlickrParameterValues.DisableJSONCallback,
            FlickrClient.Constants.FlickrParameterKeys.PerPage: FlickrClient.Constants.FlickrParameterValues.MaxPerPage,
            FlickrClient.Constants.FlickrParameterKeys.Page: "\(targetPageNumber)",
            FlickrClient.Constants.FlickrParameterKeys.BoundingBox: "\(locationParameterKey)"
            ]
        
        FlickrClient.sharedInstance().returnImageArrayFromFlickr(methodParameters) { (imageDataArray, pageTotal, error, errorDesc) in
            
            func sendError(responseKey: String, imageDictionary: [String: AnyObject]) {
                print("Cannot find key \(responseKey). For review: \n \(imageDictionary)")
                completionHandlerForGetNewPhotoArrayWithConstraints(newPhotoArray: nil, pageTotal: 1, error: true, errorDesc: "At least one photo attribute was missing from the flickr data.")
            }
            
            if !error {
                
                if let imageDictionaries = imageDataArray {
                    
                    if imageDictionaries.count > 0 {
                        
                        var newPhotoArrayToReturn: [NewPhoto] = []
                        
                        /* Pick photos randomly from those available and append them to the array */
                        let randomPhotoIndices = self.uniquePhotoIndices(min(maxPhotos, imageDictionaries.count), minIndex: 0, maxIndex: UInt32(imageDictionaries.count-1))
                        
                        print("Here are the random photo indices: \(randomPhotoIndices)")
                        
                        for index in 0...(randomPhotoIndices.count-1) {
                            
                            /* Defensive coding in case the image dictionaries do not match the expected format */
                            
                            guard let imageUrlString = imageDictionaries[randomPhotoIndices[index]][FlickrClient.Constants.FlickrResponseKeys.MediumURL] as? String else {
                                sendError(FlickrClient.Constants.FlickrResponseKeys.MediumURL, imageDictionary: imageDictionaries[randomPhotoIndices[index]])
                                return
                            }
                            
                            guard let imageTitle = imageDictionaries[randomPhotoIndices[index]][FlickrClient.Constants.FlickrResponseKeys.Title] as? String else {
                                sendError(FlickrClient.Constants.FlickrResponseKeys.Title, imageDictionary: imageDictionaries[randomPhotoIndices[index]])
                                return
                            }
                            
                            guard let imageID = imageDictionaries[randomPhotoIndices[index]][FlickrClient.Constants.FlickrResponseKeys.PhotoID] as? String else {
                                sendError(FlickrClient.Constants.FlickrResponseKeys.PhotoID, imageDictionary: imageDictionaries[randomPhotoIndices[index]])
                                return
                            }
                            
                            /* Casting to an Int directly in the guard statement above is not working */
                            if let newPhotoID = Int(imageID) {
                                let newPhoto = NewPhoto(url: imageUrlString, title: imageTitle, id: newPhotoID)
                                newPhotoArrayToReturn.append(newPhoto)
                            }
                        }
                        
                        completionHandlerForGetNewPhotoArrayWithConstraints(newPhotoArray: newPhotoArrayToReturn, pageTotal: pageTotal, error: false, errorDesc: nil)
                        
                    } else {
                        print("No images were returned")
                        completionHandlerForGetNewPhotoArrayWithConstraints(newPhotoArray: nil, pageTotal: 1, error: true, errorDesc: "No images were returned")
                    }
                    
                }
            }
            
        }
        
    }
    
    /*
    func searchFlickrForImagesForPage(targetPageNumber: Int, completionHandlerForSearchFlickrForImagesForPage: (imageDataArray: [[String:AnyObject]]?, pageTotal: Int?, error: Bool, errorDesc: String?) -> Void) {
        
        // Set method parameters
        let methodParameters: [String: String!] = [
            FlickrClient.Constants.FlickrParameterKeys.Method: FlickrClient.Constants.FlickrParameterValues.SearchMethod,
            FlickrClient.Constants.FlickrParameterKeys.APIKey: FlickrClient.Constants.FlickrParameterValues.APIKey,
            FlickrClient.Constants.FlickrParameterKeys.SafeSearch: FlickrClient.Constants.FlickrParameterValues.UseSafeSearch,
            FlickrClient.Constants.FlickrParameterKeys.Extras: FlickrClient.Constants.FlickrParameterValues.MediumURL,
            FlickrClient.Constants.FlickrParameterKeys.Format: FlickrClient.Constants.FlickrParameterValues.ResponseFormat,
            FlickrClient.Constants.FlickrParameterKeys.NoJSONCallback: FlickrClient.Constants.FlickrParameterValues.DisableJSONCallback,
            FlickrClient.Constants.FlickrParameterKeys.PerPage: FlickrClient.Constants.FlickrParameterValues.MaxPerPage,
            FlickrClient.Constants.FlickrParameterKeys.Page: "\(targetPageNumber)",
            FlickrClient.Constants.FlickrParameterKeys.Text: "London, England"
        ]
        
        FlickrClient.sharedInstance().returnImageArrayFromFlickr(methodParameters) { (imageDataArray, pageTotal, error, errorDesc) in
            
            if error == false {
                completionHandlerForSearchFlickrForImagesForPage(imageDataArray: imageDataArray, pageTotal: pageTotal, error: false, errorDesc: nil)
            } else {
                completionHandlerForSearchFlickrForImagesForPage(imageDataArray: nil, pageTotal: 1, error: true, errorDesc: errorDesc)
            }
        }
    } */
    
    func searchFlickrByPageAtLocation(locationParameterKey: String, targetPageNumber: Int, completionHandlerForSearchFlickrByPageAtLocation: (imageDataArray: [[String:AnyObject]]?, pageTotal: Int?, error: Bool, errorDesc: String?) -> Void) {
        
        // Set method parameters
        var methodParameters: [String: String!] = [
            FlickrClient.Constants.FlickrParameterKeys.Method: FlickrClient.Constants.FlickrParameterValues.SearchMethod,
            FlickrClient.Constants.FlickrParameterKeys.APIKey: FlickrClient.Constants.FlickrParameterValues.APIKey,
            FlickrClient.Constants.FlickrParameterKeys.SafeSearch: FlickrClient.Constants.FlickrParameterValues.UseSafeSearch,
            FlickrClient.Constants.FlickrParameterKeys.Extras: FlickrClient.Constants.FlickrParameterValues.MediumURL,
            FlickrClient.Constants.FlickrParameterKeys.Format: FlickrClient.Constants.FlickrParameterValues.ResponseFormat,
            FlickrClient.Constants.FlickrParameterKeys.NoJSONCallback: FlickrClient.Constants.FlickrParameterValues.DisableJSONCallback,
            FlickrClient.Constants.FlickrParameterKeys.PerPage: FlickrClient.Constants.FlickrParameterValues.MaxPerPage,
            FlickrClient.Constants.FlickrParameterKeys.Page: "\(targetPageNumber)",
        ]
        
        methodParameters[FlickrClient.Constants.FlickrParameterKeys.BoundingBox] = locationParameterKey
        
        FlickrClient.sharedInstance().returnImageArrayFromFlickr(methodParameters) { (imageDataArray, pageTotal, error, errorDesc) in
            
            if error == false {
                completionHandlerForSearchFlickrByPageAtLocation(imageDataArray: imageDataArray, pageTotal: pageTotal, error: false, errorDesc: nil)
            } else {
                completionHandlerForSearchFlickrByPageAtLocation(imageDataArray: nil, pageTotal: 1, error: true, errorDesc: errorDesc)
            }
        }
    }
    
    // MARK: - Helpers
    
    func flickrURLFromParameters(parameters: [String:AnyObject]) -> NSURL {
        
        let components = NSURLComponents()
        
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        
        /* flickr API method arguments added here */
        components.queryItems = [NSURLQueryItem]()
        for (key, value) in parameters {
            let queryItem = NSURLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.URL!
    }
    
    func isCoordinateValid(value: NSNumber, forRange: (Double, Double)) -> Bool {
        
        guard !value.doubleValue.isNaN else {
            return false
        }
        
        return isValueInRange(value.doubleValue, min: forRange.0, max: forRange.1)
    }
    
    func isValueInRange(value: Double, min: Double, max: Double) -> Bool {
        return !(value < min || value > max)
    }
    
    func boundingBoxAsString(longitude: NSNumber, latitude: NSNumber) -> String {
        
        if FlickrClient.sharedInstance().isCoordinateValid(longitude, forRange: FlickrClient.Constants.Flickr.SearchLonRange) && FlickrClient.sharedInstance().isCoordinateValid(latitude, forRange: FlickrClient.Constants.Flickr.SearchLatRange) {
            
            let bottomLeftLongi = longitude.doubleValue - Constants.Flickr.SearchBBoxHalfWidth
            let bottomLeftLati = latitude.doubleValue - Constants.Flickr.SearchBBoxHalfHeight
            
            let topRightLongi = bottomLeftLongi + (2 * Constants.Flickr.SearchBBoxHalfWidth)
            let topRightLati = bottomLeftLati + (2 * Constants.Flickr.SearchBBoxHalfHeight)
            
            return "\(max(bottomLeftLongi, Constants.Flickr.SearchLonRange.0)), \(max(bottomLeftLati, Constants.Flickr.SearchLatRange.0)), \(min(topRightLongi, Constants.Flickr.SearchLonRange.1)), \(min(topRightLati, Constants.Flickr.SearchLatRange.1))"
            
        } else {
            // The 4 values represent the bottom-left corner of the box and the top-right corner, i.e. minimum_longitude, minimum_latitude, maximum_longitude, maximum_latitude, respectively
            // *Unlike standard photo queries, geo (or bounding box) queries will only return 250 results per page*
            // https://www.flickr.com/services/api/flickr.photos.search.html
            
            /* Return the default value */
            return "-180, -90, 180, 90"
        }
    }
    
    func uniquePhotoIndices(totalPhotos: Int, minIndex: Int, maxIndex: UInt32) -> [Int] {
        
        var uniqueNumbers = Set<Int>()
        
        while uniqueNumbers.count < totalPhotos {
            uniqueNumbers.insert(Int(arc4random_uniform(maxIndex + 1)) + minIndex)
        }
        
        return Array(uniqueNumbers)
    }
    
}
