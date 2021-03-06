/*
 * Copyright (c) 2015 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit

class LoginViewController: UIViewController {
  
  // MARK: Constants
  let loginToList = "LoginToList"
  
  // MARK: Outlets
  @IBOutlet weak var textFieldLoginEmail: UITextField!
  @IBOutlet weak var textFieldLoginPassword: UITextField!
  
  @IBOutlet weak var currentUser: UILabel!
    
  //Observing Authentication State
  // Firebase has observers that allow you to monitor a user's authentication state
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // 1 Create an authentication observer using addStateDidChangeListener. The block is passsed two parameter: auth and user
    //   FIRAuth.auth()?.addStateDidChangeListener(<#T##listener: FIRAuthStateDidChangeListenerBlock##FIRAuthStateDidChangeListenerBlock##(FIRAuth, FIRUser?) -> Void#>)
    /*
    FIRAuth.auth()!.addStateDidChangeListener(){ auth, user in
      // 2 Test the value of user. Upon sucesssful user authentication, user is populated with the user's information . 
      //   if authentication fails, the variable is nil
      if user != nil {
        // 3 On successful authentication, perform the segue. (go to GroceryListTableViewController.swift)
        self.performSegue(withIdentifier: self.loginToList, sender: nil)
      }
    }
    */
    
    /* It won't get refresh while viewDidLoad
    let user = FIRAuth.auth()?.currentUser
    if let uemail = user?.email {
      textFieldLoginEmail.text = "test@gmail.com"
    } else {
      textFieldLoginEmail.text = ""
      textFieldLoginPassword.text = ""
    }
    */
    /*
    FIRAuth.auth()!.addStateDidChangeListener(){ auth, user in
      if let uemail = user?.email {
        let errAlert = UIAlertController(title: "Firebase status monitor", message: uemail, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        errAlert.addAction(okAction)
        self.present(errAlert, animated: true, completion: nil)
      }
    }
    */
  }
  
  // MARK: Actions
  @IBAction func loginDidTouch(_ sender: AnyObject) {
    // User sign in
    
    FIRAuth.auth()!.signIn(withEmail: textFieldLoginEmail.text!, password: textFieldLoginPassword.text!, completion: {
      user , error in
      
      if error == nil {
        self.performSegue(withIdentifier: self.loginToList, sender: nil)
      } else {
        let errAlert = UIAlertController(title: "Login Failed", message: "Please input your email and password", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        errAlert.addAction(okAction)
        self.present(errAlert, animated: true, completion: nil)
      }
    })
    /*
    FIRAuth.auth()!.signIn(withEmail: textFieldLoginEmail.text!, password: textFieldLoginPassword.text!)
    
    //obseleted
    //performSegue(withIdentifier: loginToList, sender: nil)
    
    FIRAuth.auth()!.addStateDidChangeListener(){ auth, user in
      // 2 Test the value of user. Upon sucesssful user authentication, user is populated with the user's information .
      //   if authentication fails, the variable is nil
      
      if user != nil {
        // 3 On successful authentication, perform the segue. (go to GroceryListTableViewController.swift)
        self.performSegue(withIdentifier: self.loginToList, sender: nil)
      }
    }
    */
  }
  
  func requiredFieldsCheck() -> Bool {
    return !(self.textFieldLoginEmail.text == "" || self.textFieldLoginPassword.text == "")
  }
  
  // 在設定 email/password 認證後, 修改此處
  @IBAction func signUpDidTouch(_ sender: AnyObject) {
    let alert = UIAlertController(title: "Register",
                                  message: "Register",
                                  preferredStyle: .alert)
    
    let saveAction = UIAlertAction(title: "Save",
                                   style: .default) { action in
        // 1 由 alert controller 獲得 email & password
        let emailField = alert.textFields![0]
        let passwordField = alert.textFields![1]
                                    
        //2 使用 Firebase auth object 來傳送 email & password
        FIRAuth.auth()!.createUser(withEmail: emailField.text!, password: passwordField.text!) { user, error in
          
          if error == nil {
            //3 如果沒有錯誤，就會建立帳號
            FIRAuth.auth()!.signIn(withEmail: self.textFieldLoginEmail.text!, password: self.textFieldLoginPassword.text!)
          }
        }
    }
    
    let cancelAction = UIAlertAction(title: "Cancel",
                                     style: .default)
    
    alert.addTextField { textEmail in
      textEmail.placeholder = "Enter your email"
    }
    
    alert.addTextField { textPassword in
      textPassword.isSecureTextEntry = true
      textPassword.placeholder = "Enter your password"
    }
    
    alert.addAction(saveAction)
    alert.addAction(cancelAction)
    
    present(alert, animated: true, completion: nil)
  }
  
}

extension LoginViewController: UITextFieldDelegate {
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    if textField == textFieldLoginEmail {
      textFieldLoginPassword.becomeFirstResponder()
    }
    if textField == textFieldLoginPassword {
      textField.resignFirstResponder()
    }
    return true
  }
  
}
