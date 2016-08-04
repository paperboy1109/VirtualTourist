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
    
    func uniquePhotoIndices(totalPhotos: Int, minIndex: Int, maxIndex: UInt32) -> [Int] {
        
        var uniqueNumbers = Set<Int>()
        
        while uniqueNumbers.count < totalPhotos {
            uniqueNumbers.insert(Int(arc4random_uniform(maxIndex + 1)) + minIndex)
        }
        
        return Array(uniqueNumbers)
    }
    
}
