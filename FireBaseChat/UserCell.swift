//
//  UserCell.swift
//  FireBaseChat
//
//  Created by lis meza on 6/11/17.
//  Copyright © 2017 Horacio Sanchez. All rights reserved.
//

import UIKit
import Firebase

class UserCell: UITableViewCell{
    
    //This User Cell contains a ImageView for the profile Image, Label for user name, 
    //and another label for the time stamps!
    
    var message: Message?{
        didSet{
        
            setUpNameAndProfileImage()
            
            if let seconds = message?.timeStamp?.doubleValue{
                
                //If we have a timeStamp, lets create a date since 1970 and a formatter
                let timeStampDate = NSDate(timeIntervalSince1970: seconds)
                let dateFormatter = DateFormatter()
                
                //We want a formate of hours:minutes:seconds
                dateFormatter.dateFormat = "hh:mm:ss a"
                //Assigned timeLabel with the formatter date
                timeLabel.text = dateFormatter.string(from: timeStampDate as Date)
            }
            
            detailTextLabel?.text = message?.text
            textLabel?.text = message?.toId
        }
    }

    private func setUpNameAndProfileImage(){
        
      
        if let id = message?.chatParterId(){
            
            //Create a reference to Firebase and observe into the selected uid child
            let ref = Database.database().reference().child("users").child(id)
            ref.observe(.value, with: { (snap) in
                
                //Create a dictionary to contain the properties of the selected uid child
                if let dictionary = snap.value as? [String:AnyObject]{
                    
                    //Assign the name property to our text label
                    self.textLabel?.text = dictionary["name"] as? String
                    
                    if let profileImageUrl = dictionary["profileImageUrl"] as? String {
                        
                        //Load the profile image using its url with the cache constructor
                        self.profileImageView.loadImageusingCacheWithUrlString(urlString: profileImageUrl)
                    }
                }
            }, withCancel: nil)
        }
}//End of setUpNameAndProfileImage()
    

    override func layoutSubviews() {
        super.layoutSubviews()
        
        //Adjust the position of the Text Label and Detail Text Label inseide each cell!
        textLabel?.frame = CGRect(x: 56, y: textLabel!.frame.midY - 14 , width: textLabel!.frame.width, height: textLabel!.frame.height)
        detailTextLabel?.frame = CGRect(x: 56, y: detailTextLabel!.frame.midY - 6, width: detailTextLabel!.frame.width, height: detailTextLabel!.frame.height)
    }
    
    let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.red
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    
    let profileImageView: UIImageView = {
        
        let profileImage = UIImageView()
        //profileImage.image = UIImage(named: "PokeCoin")
        profileImage.layer.cornerRadius = 20
        profileImage.layer.masksToBounds = true
        profileImage.translatesAutoresizingMaskIntoConstraints = false
        profileImage.contentMode = .scaleAspectFill
        return profileImage
        
    }()
    
    //Register a custom cell to user on the NewMessageViewController
    override init(style: UITableViewCellStyle, reuseIdentifier: String?){
        
        //Customize the cell to add a subtitle view
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        addSubview(profileImageView)
        addSubview(timeLabel)
        
        //profileImageView Constrains
        
        profileImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        //timeLabel Constrains
        
        timeLabel.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        timeLabel.centerYAnchor.constraint(equalTo: self.topAnchor, constant: 18).isActive = true
        timeLabel.widthAnchor.constraint(equalToConstant: 100).isActive = true
        timeLabel.heightAnchor.constraint(equalTo: (textLabel?.heightAnchor)!).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}//End of UserCell

