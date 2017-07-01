//
//  ChatLogController.swift
//  FireBaseChat
//
//  Created by lis meza on 6/8/17.
//  Copyright © 2017 Horacio Sanchez. All rights reserved.
//

import UIKit
import Firebase

class ChatLogController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    var user: User? {
        didSet{
            //Sets the Navigation Bar Title to the selected user (to send message)
            navigationItem.title = user?.name
            observeMessages()
        }
    }
    
    let cellId = "cellId"
    var messages = [Message]()
    var containerViewBottomAnchor: NSLayoutConstraint?
    lazy var inputContainerView: UIView = {
        
        //Lazy var allows us to use cell inside of this block!
        let containerView = UIView()
        containerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50)
        containerView.backgroundColor = UIColor.white
        
        let uploadImageView = UIImageView()
        uploadImageView.image = UIImage(named: "PokeCoin")
        uploadImageView.translatesAutoresizingMaskIntoConstraints = false
        uploadImageView.isUserInteractionEnabled = true
        uploadImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleUploadTap)))
        containerView.addSubview(uploadImageView)
        
        //Anchors
        uploadImageView.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 8).isActive = true
        uploadImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        uploadImageView.widthAnchor.constraint(equalToConstant: 44).isActive = true
        uploadImageView.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        //Create send button
        let sendButton = UIButton(type: .system)
        let buttonImage = UIImage(named: "wing")?.withRenderingMode(.alwaysOriginal)
        //sendButton.setTitle("send", for: .normal)
        sendButton.setImage(buttonImage, for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        
        //Don't forget to add it to the containerView
        containerView.addSubview(sendButton)
        
        //Constrains for send button
        sendButton.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        sendButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        
        //Don't forget to add it to the containerView
        containerView.addSubview(self.inputTextField)
        
        //Constrains for the inputTextField
        self.inputTextField.leftAnchor.constraint(equalTo: uploadImageView.rightAnchor, constant: 8).isActive = true
        self.inputTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        self.inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor).isActive = true
        self.inputTextField.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        let separatorLineView = UIView()
        separatorLineView.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        separatorLineView.translatesAutoresizingMaskIntoConstraints = false
        
        //Don't forget to add it to the containerView
        containerView.addSubview(separatorLineView)
        
        //Constrains for the 'separatorLineView'
        separatorLineView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        separatorLineView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        separatorLineView.widthAnchor.constraint(equalTo: containerView.widthAnchor).isActive = true
        separatorLineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return containerView
        
    }()
    
    @objc func handleUploadTap(){
        
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        
        present(imagePickerController, animated: true, completion: nil)
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        //This function Tells the delegate that the user picked a still image or movie.
        // info:
        //      - A dictionary containing the original image and the edited image, if an image was picked; or a filesystem URL for the movie, if a movie was picked. The dictionary also contains any relevant editing information. The keys for this dictionary are listed in Editing Information Keys.
        
        var selectedImagePicker: UIImage?
        
        //Assign the original or modified pictures to our 'selectedImagePicker' variable
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage{
            
            selectedImagePicker = editedImage
            
        }
        else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage{
            
            selectedImagePicker = originalImage
        }
        
        if let selectedImage = selectedImagePicker{
            
            uploadToFirebaseStorageUsingImage(image: selectedImage)
        }
        
        //Set the profile image to the selected image from photo library
        //profileImageView.image = selectedImagePicker
        dismiss(animated: true, completion: nil)
        
    }
    
    private func uploadToFirebaseStorageUsingImage(image: UIImage){
        
        let imageName = NSUUID().uuidString
        let ref = Storage.storage().reference().child("message-images").child(imageName)
        
        if let uploadData = UIImageJPEGRepresentation(image, 0.2){
            
            ref.putData(uploadData, metadata: nil, completion: { (metadata, error) in
                
                if error != nil{
                    print("fail to upload image", error as Any)
                    return
                }
                
                if let imageUrl = metadata?.downloadURL()?.absoluteString{
                    
                
                    
                    self.sendMessagWithImageUrl(imageUrl: imageUrl)
                }
            })
        }
        
    }
    
    private func sendMessagWithImageUrl(imageUrl: String){
        
        let ref = Database.database().reference().child("messages") //Make a reference to the database & create new node "messages"
        let childRef = ref.childByAutoId() // Create unique id nodes for each child of "messages"
        let toId = user?.id
        let fromId = Auth.auth().currentUser!.uid //Grab the currents user's uid
        let timeStamp = Int(NSDate().timeIntervalSince1970)
        let values = ["imageUrl": imageUrl, "toId": toId!, "fromId": fromId, "timeStamp": timeStamp] as [String : Any] //Create the expected dictionary containing the string of our text field
        childRef.updateChildValues(values) //Update the database
        inputTextField.text = nil //Erase the text when 'send' is tapped
        
        childRef.updateChildValues(values) { (error, ref) in
            
            if error != nil{
                print(error!)
                return
            }
            
            let userMessagesRef = Database.database().reference().child("user-messages").child(fromId).child(toId!)
            let messageId = childRef.key
            
            userMessagesRef.updateChildValues([messageId:1])
            
            let recipientUserMessageRef = Database.database().reference().child("user-messages").child(toId!).child(fromId)
            
            recipientUserMessageRef.updateChildValues([messageId:1])
        }
        
    }
    
    override func viewDidLoad(){
        super.viewDidLoad()
        
        collectionView?.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        //collectionView?.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        collectionView?.alwaysBounceVertical = true
        collectionView?.backgroundColor = UIColor.white
        //collectionView?.register(UICollectionViewCell.self, forCellWithReuseIdentifier: cellId)
        collectionView?.register(ChatMessageCell.self, forCellWithReuseIdentifier: cellId)
        collectionView?.keyboardDismissMode = .interactive
        
        //setupInputComponents() //Set up our Send/Message mechanism to send messages
        //setUpKeyboardObservers() //Sets up and dismiss observers when the keyboard is toggled on & off
    }
    
    override var inputAccessoryView: UIView? {
        get {
            return inputContainerView
        }
    }
    
    override var canBecomeFirstResponder : Bool {
        return true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //Remover observer to avoid memory Leaks
        NotificationCenter.default.removeObserver(self)
    }
    
    func setUpKeyboardObservers(){
        
        //This oberserver assists the keyboard showing up with out text field on top
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        //This oberserver assists the keyboard dismissing up with out text field on top
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    @objc func handleKeyboardWillHide(notification: NSNotification){
        
        //Note: This function in conjuction with 'handleKeyboardWillShow' will increment/decrement the height of the entire container view
        //according to the height of the keyboard when toggled on & off
        
        //Hide the keyboard with animation
        let keyboardDuration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue
        containerViewBottomAnchor?.constant = 0 //Need the container view at the bottom of the screen
        UIView.animate(withDuration: keyboardDuration!) {
            self.view.layoutIfNeeded()
        }
    }//End of handleKeyboardWillHide()
    
    @objc func handleKeyboardWillShow(notification: NSNotification){
        
        //Note: This function in conjuction with 'handleKeyboardWillHide' will increment/decrement the height of the entire container view
        //according to the height of the keyboard when toggled on & off
        
        //Displays the keyboard with the text field on top w/ an animation!
        let keyboardFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue
        let keyboardDuration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue
        
        //Displays the text field on top of the keyboard when toggled up
        containerViewBottomAnchor?.constant = -keyboardFrame!.height
        UIView.animate(withDuration: keyboardDuration!) {
            self.view.layoutIfNeeded()
        }
    
    }//End of handleKeyboardWillShow()
    
    func observeMessages() {
        //Obtain the current's user uid
        guard let uid = Auth.auth().currentUser?.uid, let toId = user?.id else {
            return
        }
        
        //Create a reference to Firebase under "user-messages" and locate the message using the current's user uid
        let userMessagesRef = Database.database().reference().child("user-messages").child(uid).child(toId)
        //Observe an event
        userMessagesRef.observe(.childAdded, with: { (snapshot) in
            
            //Obtain the message Id
            let messageId = snapshot.key
            //Create a new reference to Firebase under "messages" and locate the message using its Id
            let messagesRef = Database.database().reference().child("messages").child(messageId)
            //Observe a single event under the bucket to obtain a dictionary
            messagesRef.observeSingleEvent(of: .value, with: { (snapshot) in
                
                //Obtain dictionary
                guard let dictionary = snapshot.value as? [String: AnyObject] else {
                    return
                }
                
                //Initialize our 'Message' class with the obtained dictionary
                let message = Message(dictionary: dictionary)
                
                    self.messages.append(message)
                    DispatchQueue.main.async(execute: {
                    self.collectionView?.reloadData()
                })
                
            }, withCancel: nil)
            
        }, withCancel: nil)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        //This function returns a number of cells for the collection view
        return messages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var height: CGFloat = 80
        
        //Adjust the height of the bubble chat cell according to the amount of text inside of it
        if let text = messages[indexPath.item].text {
            height = estimatedframeForText(text: text).height + 20
        }
        let width = UIScreen.main.bounds.width
        
        return CGSize(width: width, height: height)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    private func estimatedframeForText(text: String) -> CGRect{
        
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        
        //This bounds our text message in a Rect size with the specified options and attributes
        //This is a CGRect!!
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 16)], context: nil)
        
    }//End of estimatedframeForText()
    
    private func setUpCell(cell: ChatMessageCell, message: Message){
        
        //Obtain the the profile image from the user and load it to our custom cell to display beneath the message in the 'ChatLogController'
        if let profileImageUrl = self.user?.profileImageUrl{
            cell.profileImageView.loadImageusingCacheWithUrlString(urlString: profileImageUrl)
        }
        //Check if the incoming message is from the current user. If it is, that means we wrote a message so it should be render blue(green) color.
        //If it's not, then it's an incoming message from a different user so it should be render out gray!
        if message.fromId == Auth.auth().currentUser?.uid{
            
            //Blue bubble chat
            cell.bubbleView.backgroundColor = ChatMessageCell.blueColor
            cell.textView.textColor = UIColor.white
            cell.profileImageView.isHidden = true
            
            cell.bubbleViewLeftAnchor?.isActive = false
            cell.bubbleViewRightAnchor?.isActive = true
            
        } else {
            //Grey Bubble Chat
            cell.bubbleView.backgroundColor = UIColor(r: 240, g: 240, b: 240)
            cell.textView.textColor = UIColor.black
            cell.profileImageView.isHidden = false
            
            cell.bubbleViewLeftAnchor?.isActive = true
            cell.bubbleViewRightAnchor?.isActive = false
        }
        
        if let messageImageUrl = message.imageUrl{
            cell.messageImageView.loadImageusingCacheWithUrlString(urlString: messageImageUrl)
            cell.messageImageView.isHidden = false
            cell.bubbleView.backgroundColor = UIColor.clear
        }else{
            cell.messageImageView.isHidden = true
        }
        
        
    }//End of setUpCell()
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ChatMessageCell
        
        let message = messages[indexPath.item]
        cell.textView.text = message.text
        setUpCell(cell: cell, message: message)
        
        
        //Sets up text bubble cell to a specified width
        if let text = message.text{
            cell.bubbleWidthAnchor?.constant = estimatedframeForText(text: text).width + 32
        }
        
        return cell
    }
    
    //Create the input text field where the user types her/his messages
    lazy var inputTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter message..."
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate = self
        return textField
        
    }()
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        //This function allows me to trigger the send button action when I press 'enter'
        handleSend()
        return true
    }
    
    @objc func handleSend(){
        
        //--------------------------------------------------------------------------------------------
        //
        // The purpose of this function is to add another uid node under "messages". This is how
        // we saved messages into FireBase.
        // Hierachical Tree View:
        //                          - messages
        //                               * uid (Unique Id for message sent)
        //                                    - fromId:     uid from sender
        //                                    - text:       message sent
        //                                    - timeStamp:  time at which the message was sent
        //                                    - toId:       uid from reciever
        //
        //                               * uid (Unique Id for message sent)
        //                                    - fromId:     uid from sender
        //                                    - text:       message sent
        //                                    - timeStamp:  time at which the message was sent
        //                                    - toId:       uid from reciever        //
        //--------------------------------------------------------------------------------------------
        
        let ref = Database.database().reference().child("messages") //Make a reference to the database & create new node "messages"
        let childRef = ref.childByAutoId() // Create unique id nodes for each child of "messages"
        let toId = user?.id
        let fromId = Auth.auth().currentUser!.uid //Grab the currents user's uid
        let timeStamp = Int(NSDate().timeIntervalSince1970)
        let values = ["text": inputTextField.text!, "toId": toId!, "fromId": fromId, "timeStamp": timeStamp] as [String : Any] //Create the expected dictionary containing the string of our text field
        childRef.updateChildValues(values) //Update the database
        inputTextField.text = "" //Erase the text when 'send' is tapped
        
        childRef.updateChildValues(values) { (error, ref) in
            
            if error != nil{
                print(error!)
                return
            }
            
            let userMessagesRef = Database.database().reference().child("user-messages").child(fromId).child(toId!)
            let messageId = childRef.key
            
            userMessagesRef.updateChildValues([messageId:1])
            
            let recipientUserMessageRef = Database.database().reference().child("user-messages").child(toId!).child(fromId)
            
            recipientUserMessageRef.updateChildValues([messageId:1])
        }
        
        
    }//End of handleSend()
    
    
}//End ChatLogController
