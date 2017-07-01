//
//  NewMessageController.swift
//  FireBaseChat
//
//  Created by lis meza on 6/1/17.
//  Copyright © 2017 Horacio Sanchez. All rights reserved.
//

import UIKit
import Firebase

class NewMessageController: UITableViewController {

    var messagesController: MessagesController?
    let cellId = "cellId" //Need a cell ID for custome cells
    var users = [User]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Register our custom cell to use in the NewMessageController
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        
        //Add left button onto the navigation bar
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "❌", style: .plain, target: self, action: #selector(handleCancel))
        fetchUser()

    }//End of viewDidLoad
    
    func fetchUser(){
        
        //We observe an event of type '.ChildAdded' to gain access to all our users registered in the database
        Database.database().reference().child("users").observe(.childAdded, with: { (snap) in
        
            //Create our dictionary containing data from Database
            if let dictionary = snap.value as? [String:AnyObject]{
                let user = User()
                user.id = snap.key
                user.name = dictionary["name"] as! String?
                user.email = dictionary["email"] as! String?
                user.profileImageUrl = dictionary["profileImageUrl"] as! String?
                //Append the users to the array users'
                self.users.append(user)
                //print(self.users)
                
                //We are in a background tread here so any modifications to the view need to happen 
                //in the main tread! So we dispatch any changes inside this block:
                
                DispatchQueue.main.async(execute: {
                    self.tableView.reloadData()
                })
                
            }
            
        }, withCancel: nil) //End of Database().reference()
        
    }//End of fetchUser()
    
    @objc func handleCancel(){
        //Dissmiss the NewMessageViewController and go back to MessagesController
        dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserCell
        
        let user = users[indexPath.row] //Fetch and add the registered users onto the New Message TableView
        cell.textLabel?.text = user.name
        cell.detailTextLabel?.text = user.email
        
        //If there's an image url, use it to download the profile imags and assign them onto the cells
        if let profileImageUrl = user.profileImageUrl{
            
            //We created an extension to UIImageView to include this custome function
            cell.profileImageView.loadImageusingCacheWithUrlString(urlString: profileImageUrl)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        //When we tap on a person to message with, Xcode calls this function and dissmisses the current view,
        //grabs the index of the tapped cell and calls 'showChatControllerForUser' passing that user as a reference!
        
        dismiss(animated: true, completion: nil) //Dismiss current view
        let user = users[indexPath.row] // Grab cell index row
        self.messagesController?.showChatControllerForUser(user: user) //Show the ChatController view
        
        
    }
    
    //change the height of the cells in the tableView
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }


}//End of NewMessageController
















