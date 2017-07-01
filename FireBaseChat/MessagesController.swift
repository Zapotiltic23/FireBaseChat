//
//  ViewController.swift
//  FireBaseChat
//
//  Created by lis meza on 4/7/17.
//  Copyright © 2017 Horacio Sanchez. All rights reserved.
//

import UIKit
import Firebase

class MessagesController: UITableViewController {
    
    var messages = [Message]() //Create array of messages to store info about messages sent (a.k.a: fromId, toId, text, timeStamp)
    let cellId = "cellId"
    var messagesDictionary = [String: Message]()
    var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Choose an image for the New Message Bar Button
        
        //let newMsgButtonImage = UIImage(named: "scale")?.withRenderingMode(.alwaysOriginal)
        //navigationItem.rightBarButtonItem = UIBarButtonItem(image: newMsgButtonImage, style: .plain, target: self, action: #selector(handleNewMessage))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "✏️", style: .plain, target: self, action: #selector(handleNewMessage))
        // Create the "Logout" button and give it and action to perform when tapped.
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "⏎", style: .plain, target: self, action: #selector(handleLogout))
        
        //Register our custom cell to use on our table view!
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        
        checkIfUserIsLoggedIn()
        //observeMessages()
        
        
    }//End of viewDidLoad()
    
    func observeUserMessages(){
        
        //Get the current's user uid
        guard let uid = Auth.auth().currentUser?.uid else{
            return
        }
        
        //Create a reference to the database and a new node under "user-messages" using 
        //the current's user uid
        let ref = Database.database().reference().child("user-messages").child(uid)
        
        //Observe inside the newly created node and extract values from dictionary
        ref.observe(.childAdded, with: { (snap) in
            
            let userId = snap.key // Get the key from the snap dictionary [key:value]
            
            Database.database().reference().child("user-messages").child(uid).child(userId).observeSingleEvent(of: .childAdded, with: { (snap) in
                
                //Go one level deeper and observe a node under:
                //--------------------------------------------------------------------------------------------
                //
                // The purpose of this function is to add another uid node under "user-messages". This is how
                // we saved messages into FireBase.
                // Hierachical Tree View:
                //                          - user-messages
                //                                  * uid
                //                                      - userId (Observing this bucket!)
                //                                          * "message"
                //
                //                          - user-messages
                //                                  * uid
                //                                      - userId
                //                                          * "message"
                //--------------------------------------------------------------------------------------------
                
                let messageId = snap.key
                self.fetchMessageWithMessageId(messageId: messageId)
                
            }, withCancel: nil)
            
        }, withCancel: nil)
    }//End of observeUserMessages()
    
    
    private func fetchMessageWithMessageId(messageId: String){
        
        //Create a reference to Firebase under the "messages" nodes under the 'messageId'
        let messageRefrence = Database.database().reference().child("messages").child(messageId)
        
        //Observe inside the node and get a dictionary
        messageRefrence.observeSingleEvent(of: .value, with: { (snap) in
            
            if let dictionary = snap.value as? [String:AnyObject]{
                
                let message = Message(dictionary: dictionary)//Create a reference to our message array
                
                //Assign values to our class' properties
                message.fromId = dictionary["fromId"] as! String?
                message.toId = dictionary["toId"] as! String?
                message.timeStamp = dictionary["timeStamp"] as! NSNumber?
                message.text = dictionary["text"] as! String?
                
                if let chatParterId = message.chatParterId(){
                    self.messagesDictionary[chatParterId] = message
                }
                
                self.attemptReloadTable()
            }
            
        }, withCancel: nil)
        
    }//End of fetchMessageWithMessageId
    
    
    private func attemptReloadTable(){
        
        //We need to invalidate the timer before we can re-schedule another one! So always invalidate 1st
        self.timer?.invalidate()
        
        //Schedule a timer to reduce the amount of times we reload the table and thus make the profile image view correspond the right user!
        self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.handleReloadTable), userInfo: nil, repeats: false)
        
    } //End of attemptReloadTable()
    
    
    @objc func handleReloadTable(){
        
        //NOTE: We only need to resconstruct the messages and sort the array when we reload the table!
        
        //Sort our messages by time recieved using a the stamp!
        self.messages = Array(self.messagesDictionary.values) //This is an array of 'Messages' values asigned to another array of 'Messages' type :)
        
        self.messages.sort(by: { (m1, m2) -> Bool in
            
            return (m1.timeStamp?.intValue)! > (m2.timeStamp?.intValue)!
        })
        
        //We are in a background tread here so any modifications to the view need to happen
        //in the main tread! So we dispatch any changes inside this block:
        
        DispatchQueue.main.async(execute: {
            print("We reloaded the table!!!")
            self.tableView.reloadData()
        })
        
    } //End of handleReloadTable
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    //change the height of the cells in the tableView
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        //This function allows me to bring up the ChaLog for a selected user (row) in Messages
        
        let message = messages[indexPath.row]
        
        //Get the uid from the user you want to chat with
        guard let chatPartnerId = message.chatParterId() else{
            return
        }
        
        //Create a reference to Firebase & observe a single value event
        let ref = Database.database().reference().child("users").child(chatPartnerId)
        
        ref.observeSingleEvent(of: .value, with: { (snap) in
            
            //Get the dictionary out of Firebase
            guard let dictionaty = snap.value as? [String:AnyObject] else{
                return
            }
            
            //This user is the one you selected from Messages
            let user = User()
            user.id = chatPartnerId
            
            //Set all the user's info
            
            user.email = dictionaty["email"] as? String
            user.profileImageUrl = dictionaty["profileImageUrl"] as? String
            user.name = dictionaty["name"] as? String
            
            //Show the ChatLog for the chosen user
            self.showChatControllerForUser(user: user)
            
            
        }, withCancel: nil)
       
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        //Deque a cell and downcast a 'UserCell'.....(our custome cell!)
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserCell
        let message = messages[indexPath.row]
        cell.message = message
        
        return cell
    }
    
    
    @objc func handleNewMessage(){
        
        // This function is called when the user taps the New Message Button. This will present our NewMessageViewController.
        
        let newMessageController = NewMessageController() //Capture ViewController to present
        newMessageController.messagesController = self
        let navController = UINavigationController(rootViewController: newMessageController) //Add a navigation bar to the ViewController
        present(navController, animated: true, completion: nil) // Present the ViewController
        
        print("Icon works")
    }//End of handleNewMessage()

    func checkIfUserIsLoggedIn(){
        
        //If User is NOT logged in, kick him/her out of the main view onto the registratio/login screen
        //Else, we want to access the database and start fetching its contents!
        
        if Auth.auth().currentUser?.uid == nil{
            perform(#selector(handleLogout), with: nil, afterDelay: 0)
        }else{
            
            fetchUserAndSetUpNavBarTitle()
        }

    }//End of checkIfUserIsLoggedIn()
    
    func fetchUserAndSetUpNavBarTitle(){
        
        //This function calls the database to retrieve the user's name and assigned to the navigation bar as title
        guard let uid = Auth.auth().currentUser?.uid else{
            return
        }//Capture users UID
        
        //Make a reference to the database and fetch a single event
        Database.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with: { (snap) in
            
            //Create dictionary to fetch its contents
            if let dictionary = snap.value as? [String:AnyObject]{
                
                let user = User()
                user.name = dictionary["name"] as! String?
                user.email = dictionary["email"] as! String?
                user.profileImageUrl = dictionary["profileImageUrl"] as! String?

                //self.navigationItem.title = dictionary["name"] as? String
                self.setUpNavBarWithUser(user: user)
            }
            
        }, withCancel: nil)

        
    }//End of fetchUserAndSetUpNavBarTitle()
    
    func setUpNavBarWithUser(user: User){
        
        //This function allows me to set up the navigation bar in 'MessagesController' with the current's user name and profile image view!
        
        messages.removeAll()
        messagesDictionary.removeAll()
        tableView.reloadData()
        
        observeUserMessages()
        
        
        let titleView = UIView()
        titleView.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        titleView.addSubview(containerView)
        
        let profileImageView = UIImageView()
        if let profileImageUrl = user.profileImageUrl{
            
            profileImageView.translatesAutoresizingMaskIntoConstraints = false
            profileImageView.contentMode = .scaleAspectFill
            profileImageView.layer.cornerRadius = 20
            profileImageView.clipsToBounds = true
            profileImageView.loadImageusingCacheWithUrlString(urlString: profileImageUrl)
        }
        
        containerView.addSubview(profileImageView)

        
        //Add 'profileImageView' Constrains
        
        profileImageView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        //Add 'nameLabel' Constrains
        let nameLabel = UILabel()
        containerView.addSubview(nameLabel)
        nameLabel.text = user.name
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        nameLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8).isActive = true
        nameLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        nameLabel.heightAnchor.constraint(equalTo: profileImageView.heightAnchor).isActive = true
        
        containerView.centerXAnchor.constraint(equalTo: titleView.centerXAnchor).isActive = true
        containerView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor).isActive = true
        
        
        self.navigationItem.titleView = titleView
        
    }
    
    func showChatControllerForUser(user: User){
        
        //We called this function from 'NewMessagesController'. This parameter contains the selected row index when user wants 
        //to send a new message
        
        //To present/push the chat log controller, create a reference to it and then push it to the stack for viewing!
        let chatLogController = ChatLogController(collectionViewLayout: UICollectionViewFlowLayout())
        chatLogController.user = user //This user contains the cell index row of the tapped row in the table to start a new message
        navigationController?.pushViewController(chatLogController, animated: true)
    }
    
    @objc func handleLogout(){
        
        //Sign out the user
        do{
            try Auth.auth().signOut()
        } catch let logoutError {
            print(logoutError)
        }
        
        // Every time the logout button is tapped, we are presented with the login screen.
        // Create the ViewController to present (login page) then presented to our screen
        let loginController = LoginController()
        loginController.messagesController = self
        present(loginController, animated: true, completion: nil)
    }
    
}

