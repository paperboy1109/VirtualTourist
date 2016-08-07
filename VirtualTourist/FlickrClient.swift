//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Daniel J Janiak on 8/4/16.
//  Copyright © 2016 Daniel J Janiak. All rights reserved.
//

import UIKit

class FlickrClient: NSObject {
    
    // MARK: - Shared Instance
    
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
    
    // MARK: - Properties
    
    var session = NSURLSession.sharedSession()    
    
    // MARK: - Return images from flickr given a dictionary of flickr method parameters
    
    func returnImageArrayFromFlickr(methodParameters: [String:AnyObject], completionHandlerForReturnImageArrayFromFlickrBySearch: (imageDataArray: [[String:AnyObject]]?, pageTotal: Int?, error: Bool, errorDesc: String?) -> Void) {
        
        // What parameters were received?
        // print(flickrURLFromParameters(methodParameters))
        
        // Make a request to Flickr!
        let request = NSURLRequest(URL: flickrURLFromParameters(methodParameters))
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                print("There was an error with your request: \(error)")
                completionHandlerForReturnImageArrayFromFlickrBySearch(imageDataArray: nil, pageTotal: 1, error: true, errorDesc: "There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                completionHandlerForReturnImageArrayFromFlickrBySearch(imageDataArray: nil, pageTotal: 1, error: true, errorDesc: "Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                completionHandlerForReturnImageArrayFromFlickrBySearch(imageDataArray: nil, pageTotal: 1, error: true, errorDesc: "No data was returned by the request!")
                return
            }
            
            // For debugging only
            //print("*** Here is the raw data ***")
            //print(data)
            
            // TODO: There should potentially be a separate method for this
            // parse the data
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                completionHandlerForReturnImageArrayFromFlickrBySearch(imageDataArray: nil, pageTotal: 1, error: true, errorDesc: "Could not parse the data as JSON: '\(data)'")
                return
            }
            
            // For debugging only
            print("\n(returnImageArrayFromFlickr)*** Here is the parsed result: ")
            print("muted")
            // print(parsedResult)
            
            /* GUARD: Are the "photos" and "photo" keys in our result? */
            // Notes:
            // - 'photos' is a key in a dictionary; its value is a dictionary.
            // - The 'photos' dictionary includes the key 'photo' which returns AN ARRAY of dictionaries; each such dictionary describes an individual photo
            guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject],
                photoArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String:AnyObject]] else {
                    //displayError("Cannot find keys '\(Constants.FlickrResponseKeys.Photos)' and '\(Constants.FlickrResponseKeys.Photo)' in \(parsedResult)")
                    completionHandlerForReturnImageArrayFromFlickrBySearch(imageDataArray: nil, pageTotal: 1, error: true, errorDesc: "Cannot find keys '\(Constants.FlickrResponseKeys.Photos)' and '\(Constants.FlickrResponseKeys.Photo)' in \(parsedResult)")
                    return
            }
            
            // Prevent crash if no photos are returned
            if photoArray.count == 0 {
                completionHandlerForReturnImageArrayFromFlickrBySearch(imageDataArray: nil, pageTotal: 1, error: true, errorDesc: "No photos were returned")
                return
            }
            
            
            // For debugging:
            //print("Here is photoArray: \(photoArray)")
            //print("Here is the number of photos: \(photoArray.count)")
            
            print("Here is the number of pages: ")
            print(photosDictionary[Constants.FlickrResponseKeys.Pages])
            
            // Prevent crash if there is a problem getting the number of pages of photos
            guard let pageTotal = photosDictionary[Constants.FlickrResponseKeys.Pages] as? Int else {
                print("No page count!")
                completionHandlerForReturnImageArrayFromFlickrBySearch(imageDataArray: photoArray, pageTotal: 1, error: false, errorDesc: nil)
                return
            }
            
            print("Here is pageTotal:\(pageTotal)")
            
            completionHandlerForReturnImageArrayFromFlickrBySearch(imageDataArray: photoArray, pageTotal: pageTotal, error: false, errorDesc: nil)
        }
        
        task.resume()
    }
    
    // MARK: - Return images based on urls
    
    func returnImageFromFlickrByURL(urlString: String, completionHandlerForReturnImageFromFlickrByURL: (imageData: NSData?, error: Bool, errorDesc: String?) -> Void) {
        
        let url = NSURL(string: urlString)!
        
        let task = session.dataTaskWithURL(url) { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                print("There was an error with your request: \(error)")
                completionHandlerForReturnImageFromFlickrByURL(imageData: nil, error: true, errorDesc: "There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                // displayError("Your request returned a status code other than 2xx!")
                completionHandlerForReturnImageFromFlickrByURL(imageData: nil, error: true, errorDesc: "Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                //displayError("No data was returned by the request!")
                completionHandlerForReturnImageFromFlickrByURL(imageData: nil, error: true, errorDesc: "No data was returned by the request!")
                return
            }
            
            completionHandlerForReturnImageFromFlickrByURL(imageData: data, error: false, errorDesc: nil)
            
            
        }
        
        task.resume()
    }
    
    // MARK: - Return an array of NewPhoto objects given contstraints on the (flickr) page number and the total number of objects
    
    func getRandomSubsetPhotoDataArrayFromFlickr(targetPage: Int, maxPhotos: Int, completionHandlerForGetRandomSubsetPhotoDataArrayFromFlickr: (newPhotoArray: [NewPhoto]?, pageTotal:Int?, error: Bool, errorDesc: String?) -> Void) {
        
        print("\n\n\n ***** \n getRandomSubsetPhotoDataArrayFromFlickr called")
        
        FlickrClient.sharedInstance().searchFlickrForImagesForPage(targetPage) { (imageDataArray, pageTotal, error, errorDesc) in
            
            if !error {
                
                if let imageDictionaries = imageDataArray {
                    
                    // For debugging
                    print("\n*Here is the number of image dictionaries: ")
                    print(imageDictionaries.count)
                    print("Here is the parsed data:")
                    print("muted")
                    // print(imageDictionaries)
                    
                    if imageDictionaries.count > 0 {
                        
                        // print(imageDictionaries[0])
                        
                        var newPhotoArrayToReturn: [NewPhoto] = []
                        
                        func sendError(responseKey: String, imageDictionary: [String: AnyObject]) {
                            print("Cannot find key \(responseKey). For review: \n \(imageDictionary)")
                            completionHandlerForGetRandomSubsetPhotoDataArrayFromFlickr(newPhotoArray: nil, pageTotal: 1, error: true, errorDesc: "At least one photo attribute was missing from the flickr data.")
                        }
                        
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
                            
                            /* Casting to an Int is not working in the guard statement */
                            if let newPhotoID = Int(imageID) {
                                let newPhoto = NewPhoto(url: imageUrlString, title: imageTitle, id: newPhotoID)
                                newPhotoArrayToReturn.append(newPhoto)
                            }
                            
                            
                        }
                        
                        completionHandlerForGetRandomSubsetPhotoDataArrayFromFlickr(newPhotoArray: newPhotoArrayToReturn, pageTotal: pageTotal, error: false, errorDesc: nil)
                        
                        
                    } else {
                        print("No images were returned")
                        completionHandlerForGetRandomSubsetPhotoDataArrayFromFlickr(newPhotoArray: nil, pageTotal: 1, error: true, errorDesc: "No images were returned")
                    }
                    
                }
            }
        }
    }
    

}
