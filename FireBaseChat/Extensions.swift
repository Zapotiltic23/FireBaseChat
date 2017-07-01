//
//  Extensions.swift
//  FireBaseChat
//
//  Created by lis meza on 6/3/17.
//  Copyright © 2017 Horacio Sanchez. All rights reserved.
//

import UIKit

let imageCache = NSCache<AnyObject, AnyObject>()

//Create extension for the Coloring of the backgroudview

extension UIColor{
    
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat){
        self.init(red: r/255, green: g/255, blue: g/255, alpha: 1)
    }
    
}//End of UIColor extension

extension UIImageView{
    
    func loadImageusingCacheWithUrlString(urlString: String){
        
        self.image = nil
        //Check cache image first. If there's a cached imaged, let's use it before trying to download from FireBase
        if let cachedImage = imageCache.object(forKey: urlString as AnyObject) as? UIImage{
            
            self.image = cachedImage //Use cached image
            return //Exit the function
        }
        
        //Let's download image from FireBase using our urlSring
        let url = URL(string: urlString)
        URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) in
            
            //if we hit an error, we print & return out
            if error != nil{
                print(error!)
                return
            }
            
            //Succesfully downloaded image data
            
            
                
                DispatchQueue.main.async(execute: {
                    if let downloadedImage  = UIImage(data: data!){
                        
                        imageCache.setObject(downloadedImage, forKey: urlString as AnyObject) // Saved downloaded image to the cache
                        self.image = downloadedImage // Set the profile images to the cell view
                    }
                    
                })
                
            
            
            
        }).resume() //resume session so the changes take effect
    }

    
}


