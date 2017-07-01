//
//  LoginController+handlers.swift
//  FireBaseChat
//
//  Created by lis meza on 6/2/17.
//  Copyright © 2017 Horacio Sanchez. All rights reserved.
//

import UIKit
import Firebase

//Any functions inside of this extension can be used in 'LoginController' as if they were declared there!
extension LoginController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
  @objc func handleSelectProfileImageView(){
        
        //You need access to the user's Photo Library in order to use this ImagePicker. Go to Info.plist and add a new 'Privacy - Photo Library Usage Description' under 'Information Property List'. When you add the description, add also a string with the message the user will see when the app asks for permission to use the Photo Library
        let picker = UIImagePickerController()
        present(picker, animated: true, completion: nil)
        
        picker.delegate = self
        picker.allowsEditing = true //Gives the ability to edit the photo before selecting it
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
        
        //Set the profile image to the selected image from photo library
        profileImageView.image = selectedImagePicker
        dismiss(animated: true, completion: nil)

    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        //This function Tells the delegate that the user cancelled the pick operation. Your delegate’s implementation of this method should dismiss the picker view by calling the dismissModalViewControllerAnimated: method of the parent view controller.
        dismiss(animated: true, completion: nil)
    }
    
     @objc func handleRegisterChange(){
        
        //Grab the title of the segemented control at the selected index then set that title to the register button.
        let title = loginRegisterSegmentedControl.titleForSegment(at: loginRegisterSegmentedControl.selectedSegmentIndex)
        loginRegisterButton.setTitle(title, for: .normal)
        
        //First Change height of inputContainerView
        //Use the segmented control index to determine what height to assign. If h = 0 then assign 100, else assign 150
        inputsContainerViewHeightAnchor?.constant = loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 90 : 150
        
        //Change height of nameTextField
        nameTextFieldHeightAnchor?.isActive = false
        nameTextFieldHeightAnchor = nameTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 0 : 1/3)
        nameTextFieldHeightAnchor?.isActive = true
        
        //Change height of emailTextField
        emailTextFieldHeightAnchor?.isActive = false
        emailTextFieldHeightAnchor = emailTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 1/2 : 1/3)
        emailTextFieldHeightAnchor?.isActive = true
        
        //Change height of passwordTextField
        passwordTextFieldHeightAnchor?.isActive = false
        passwordTextFieldHeightAnchor = passwordTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 1/2 : 1/3)
        passwordTextFieldHeightAnchor?.isActive = true
        
    }//End of handleRegisterChange()
    
    @objc func handleLoginRegister(){
        if loginRegisterSegmentedControl.selectedSegmentIndex == 0{
            handleLogin()
        }else{
            handleRegister()
        }
    }
    
    func handleLogin(){
        
        //If the user enters an garbage on the textfields, we return!
        guard let email = emailTextField.text, let password = passwordTextField.text else{
            print("Invalid Form")
            return
        }
        //Else we sign in using the given credentials
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
            
            if error != nil{
                print(error!)
                return
            }
            //Succesfully logged in our user
            self.messagesController?.fetchUserAndSetUpNavBarTitle()
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func handleRegister(){
        
        //Capture the email, password and name from the user's input on their respective textfields
        guard let email = emailTextField.text, let password = passwordTextField.text, let name = nameTextField.text else{
            print("Invalid Form")
            return
        }
        
        //Call this method to create a user in FireBase using email
        Auth.auth().createUser(withEmail: email, password: password, completion:  { (user, error) in
            
            if error != nil{
                print(error!)
                return
            }
            
            //This captures the user's unique ID string given by FireBase
            guard let uid = user?.uid else{
                return
            }
            
            //**Succesfully authenticated the user**
            
            let imageName = NSUUID().uuidString
            let storage = Storage.storage().reference().child("profile_images").child("\(imageName).png")// Create a reference to the storage in FireBase
            
            if let profileImage = self.profileImageView.image, let uploadImage = UIImageJPEGRepresentation(profileImage, 0.1){
            
            //Use JPEG representation to avoid uploading/downloading heavy images
            
                //Upload data calling the method: 'putData' w/ completion handler
                storage.putData(uploadImage, metadata: nil, completion: { (metadata, error) in
                    
                    if error != nil{
                        print(error!)
                    }
                    
                    if let profileImageUrl = metadata?.downloadURL()?.absoluteString{
                        
                        let values = ["name": name, "email" : email, "profileImageUrl": profileImageUrl]// Our database is a dictionary that stores name & email
                        
                        self.registerUserIntoDatabaseWithUid(uid: uid, values: values as [String : AnyObject])
                    }
                    
                })
                
            }
            
        })//End of createUser()
        
    }//End of handleRegister()
    
    private func registerUserIntoDatabaseWithUid(uid: String, values: [String:AnyObject]){
        
        //--------------------------------------------------------------------------------------------
        //
        // The purpose of this function is to add another uid node under "users". This is how
        // we register a new user into FireBase.
        // Hierachical Tree View:
        //                          - users
        //                               * uid (Newly Registered User)
        //                                    - name:            Alex
        //                                    - email:           test1@gmail.com
        //                                    - profileImageUrl: https//www.someimageurl.jpg
        //
        //                               * uid (Registered User)
        //                                    - name:            Horacio
        //                                    - email:           test2@gmail.com
        //                                    - profileImageUrl: https//www.someimageurl2.jpg
        //
        //--------------------------------------------------------------------------------------------

        
        //Create a reference to link to our database by providing our FireDB link
        //let ref = Database.database().reference(fromURL: "https://whisper-aae1b.firebaseio.com/")
        let ref = Database.database().reference()

        
        //Create user's reference to the database to write and save information to the DB
        let userReference = ref.child("users").child(uid) //Creates node (tree hierarchical view)
        
        userReference.updateChildValues(values, withCompletionBlock: { (err, ref) in
            
            if err != nil {
                print(err!)
                return
            }
            
            // Assign the 'User' class properties w/ their respective values from FireBase.
            let user = User()
            user.name = values["name"] as! String?
            user.email = values["email"] as! String?
            user.profileImageUrl = values["profileImageUrl"] as! String?
            
            self.messagesController?.setUpNavBarWithUser(user: user)
            //self.messagesController?.fetchUserAndSetUpNavBarTitle()
            //self.messagesController?.navigationItem.title = values["name"] as? String
            
            self.dismiss(animated: true, completion: nil)
            print("Saved user sucesfully onto Firebase DB")
            
        })//End of updateChildValues()

    }
    
    func setupLoginRegisterSegementedControl(){
        
        //Setup constrains of the segemented controller
        loginRegisterSegmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loginRegisterSegmentedControl.bottomAnchor.constraint(equalTo: inputsContainerView.topAnchor, constant: -12).isActive = true
        loginRegisterSegmentedControl.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor, multiplier: 0.5).isActive = true
        loginRegisterSegmentedControl.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
    }//End of setupLoginRegisterSegementedControl()
    
    func setupProfileImageView() {
        
        //Setting the center, bottom, width and height of the profile view image
        profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        profileImageView.bottomAnchor.constraint(equalTo: loginRegisterSegmentedControl.topAnchor, constant: -12).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 150).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 150).isActive = true
        
    }//End setupProfileImageView()
    
    func setupInputsContainerView(){
        
        //Add constrains to the inputViewController
        inputsContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        inputsContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        inputsContainerView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -24).isActive = true
        inputsContainerViewHeightAnchor = inputsContainerView.heightAnchor.constraint(equalToConstant: 150)
        inputsContainerViewHeightAnchor?.isActive = true
        
        //Add the different textfields and views as subviews to show inside inputViewController
        inputsContainerView.addSubview(nameTextField)
        inputsContainerView.addSubview(nameSeparatorView)
        inputsContainerView.addSubview(emailTextField)
        inputsContainerView.addSubview(passwordTextField)
        inputsContainerView.addSubview(emailSeparatorView)
        
        //Set up constrains of 'nametextField' textfield!
        nameTextField.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor, constant: 12).isActive = true
        nameTextField.topAnchor.constraint(equalTo: inputsContainerView.topAnchor).isActive = true
        nameTextField.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        nameTextFieldHeightAnchor = nameTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/3)
        nameTextFieldHeightAnchor?.isActive = true
        
        //Set up constrains of 'nameSeparatorView' view!
        nameSeparatorView.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor).isActive = true
        nameSeparatorView.topAnchor.constraint(equalTo: nameTextField.bottomAnchor).isActive = true
        nameSeparatorView.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        nameSeparatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        //Set up constrains of 'emailTextField' textfield!
        emailTextField.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor, constant: 12).isActive = true
        emailTextField.topAnchor.constraint(equalTo: nameTextField.bottomAnchor).isActive = true
        emailTextField.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        emailTextFieldHeightAnchor = emailTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/3)
        emailTextFieldHeightAnchor?.isActive = true
        
        
        //Set up constrains of 'emailSeparatorView' view!
        emailSeparatorView.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor).isActive = true
        emailSeparatorView.topAnchor.constraint(equalTo: emailTextField.bottomAnchor).isActive = true
        emailSeparatorView.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        emailSeparatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        //Set up constrains of 'passwordTextField' textfield!
        passwordTextField.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor, constant: 12).isActive = true
        passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor).isActive = true
        passwordTextField.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        passwordTextFieldHeightAnchor = passwordTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/3)
        passwordTextFieldHeightAnchor?.isActive = true
        
        
    }//End of setupInputsContainerView()
    
    func setupRegisterButton(){
        
        //Set up constrains of the login button
        loginRegisterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loginRegisterButton.topAnchor.constraint(lessThanOrEqualTo: inputsContainerView.bottomAnchor, constant: 12).isActive = true
        loginRegisterButton.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        loginRegisterButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
    }//End of setupRegisterButton()

}
