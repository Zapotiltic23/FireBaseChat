//
//  Message.swift
//  FireBaseChat
//
//  Created by lis meza on 6/9/17.
//  Copyright © 2017 Horacio Sanchez. All rights reserved.
//

import UIKit
import Firebase

class Message: NSObject {
    
    var fromId: String?
    var text: String?
    var timeStamp: NSNumber?
    var toId: String?
    var imageUrl: String?
    var imageHeight: NSNumber?
    var imageWidth: NSNumber?
    
    init(dictionary: [String: AnyObject]) {
        super.init()
        self.fromId = dictionary["fromId"] as? String
        self.text = dictionary["text"] as? String
        self.toId = dictionary["toId"] as? String
        self.imageUrl = dictionary["imageUrl"] as? String
        
        self.timeStamp = dictionary["timeStamp"] as? NSNumber
        self.imageWidth = dictionary["imageWidth"] as? NSNumber
        self.imageHeight = dictionary["imageHeight"] as? NSNumber
    }
    
    func chatParterId() -> String?{
        
        //If the incoming message id is from the current user, we assign the recipient's id to
        //'chatPartnerId'. Else we assign the incoming message id to 'chatPartnerId'.
        
        if fromId == Auth.auth().currentUser?.uid{
            return toId
        }else{
            return fromId
        }
        
    }//End of chatParterId()

}//End of Message


