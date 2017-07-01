//
//  LoginController.swift
//  FireBaseChat
//
//  Created by lis meza on 4/7/17.
//  Copyright © 2017 Horacio Sanchez. All rights reserved.
//
// This is the the ViewController for the Loging screen!

import UIKit
import Firebase

class LoginController: UIViewController {
    
    
    
    //Use this references to adjust height of 'inputsContainerView' and its residents
    @objc var inputsContainerViewHeightAnchor: NSLayoutConstraint?
    var nameTextFieldHeightAnchor: NSLayoutConstraint?
    var emailTextFieldHeightAnchor: NSLayoutConstraint?
    var passwordTextFieldHeightAnchor: NSLayoutConstraint?
    var messagesController: MessagesController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //change background color
        view.backgroundColor = UIColor(r: CGFloat(255), g: CGFloat(70), b: CGFloat(12))
        
        //Add the subview container and Register button to the screen
        view.addSubview(inputsContainerView)
        view.addSubview(loginRegisterButton)
        view.addSubview(profileImageView)
        view.addSubview(loginRegisterSegmentedControl)
        
        //Set up the view container and button constrains with our specified dimensions
        setupInputsContainerView()
        setupRegisterButton()
        setupProfileImageView()
        setupLoginRegisterSegementedControl()
        
    }//End of viewDidLoad()
    
    //Create the middle white container view for user input
    let inputsContainerView :UIView = {
        
        let view = UIView()
        
        view.backgroundColor = UIColor.white
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 5 //Get rounded edges on the container view
        view.layer.masksToBounds = true
        return view
        
    }()//End of inputsContainerView
    
    //Ceate the register button
    lazy var loginRegisterButton: UIButton = {
        
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(r: CGFloat(255), g: CGFloat(100), b: CGFloat(12))
        //button.backgroundColor = UIColor(r: CGFloat(8), g: CGFloat(79), b: CGFloat(232))
        button.setTitle("Register", for: .normal)
        button.setTitleColor(UIColor.black, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        //Add function to call when tapping the 'register' button
        button.addTarget(self, action: #selector(handleLoginRegister), for: .touchUpInside)
        
        return button
    }()
    
        
    //Create name TextField
    let nameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Name"
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    //Create separator line between textfields
    let nameSeparatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    //Create email TextField
    let emailTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Email"
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    //Create password TextField
    let passwordTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Password"
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    //Create separator line between textfields
    let emailSeparatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    //Create the profile image view
    lazy var profileImageView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = UIColor.clear
        view.image = UIImage(named: "Logo")
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleSelectProfileImageView)))
        view.contentMode = .scaleAspectFit
        view.isUserInteractionEnabled = true //Set to true to be able to tap image
        return view
    }()

    //Contruct our segmented Login/Register controller
    lazy var loginRegisterSegmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Login", "Register"]) //Specify name and # of buttons in controller
        sc.translatesAutoresizingMaskIntoConstraints = false
        sc.tintColor = UIColor.white
        sc.selectedSegmentIndex = 1 //Selects index one by default
        sc.addTarget(self, action: #selector(handleRegisterChange), for: .valueChanged) //Add function to call when controller tapped
        return sc
    }()

        
    

    //Change the color of the status bar in the navigation controller area in our app
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
        
    }//End of preferredStatusBarStyle
    
}//End of LoginController


