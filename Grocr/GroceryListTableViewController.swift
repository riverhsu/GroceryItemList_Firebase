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

class GroceryListTableViewController: UITableViewController {

  // MARK: Constants
  let listToUsers = "ListToUsers"
  
  //creating a connection to Firebase
  let ref = FIRDatabase.database().reference(withPath: "grocery-items")
  
  //Monitoring users' Online Status
  // Firebase 指定 on-line users 的 table (JSON)
  let usersRef = FIRDatabase.database().reference(withPath: "online")
  
  // MARK: Properties 
  var items: [GroceryItem] = []
  var user: User!
  var userCountBarButtonItem: UIBarButtonItem!
  
  // MARK: UIViewController Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tableView.allowsMultipleSelectionDuringEditing = false
    
    userCountBarButtonItem = UIBarButtonItem(title: "1",
                                             style: .plain,
                                             target: self,
                                             action: #selector(userCountButtonDidTouch))
    userCountBarButtonItem.tintColor = UIColor.white
    navigationItem.leftBarButtonItem = userCountBarButtonItem
    
    // MARK: Setting the user in the Grocery List
    //   attach an authentication observer to the Firebase auth object, that in turn assigns the user property when a user successfully signs in
    // user = User(uid: "FakeId", email: "hungry@person.food")
    FIRAuth.auth()!.addStateDidChangeListener { auth, user in
      guard let user = user else {return }
      self.user = User(authData: user)
      
      // Monitoring Users' Online status 
      // 1 Create a child reference using a user's uid, which is generated when Firebase creates an account
      let currentUserRef = self.usersRef.child(self.user.uid)
      
      // 2 Use this reference to sve the current user's email
      currentUserRef.setValue(self.user.email)
      // 3 This removes the value of the reference's location after the connection to Firebase closes. This is for monitoring users who have gone offline
      currentUserRef.onDisconnectRemoveValue()
      
    }
    
    // Updating the Online User count
    // This create an observer to monitor online users. When users go on-and-offline, the title of userCountbarButtonItem updates the user count
    usersRef.observe(.value, with: { snapshot in
      if snapshot.exists(){
        self.userCountBarButtonItem?.title = snapshot.childrenCount.description
      } else {
        self.userCountBarButtonItem?.title = "0"
      }
    })
    
    
    // ***** Phase I Retrieving data only**********
    /*
    // by attaching an asychronous listener to a reference using below
    // parameters: 
    // 1. (listen to events) an instance of FIRDataEventType : what event you want to listen for. Here listen for a .value event type, which in turn listens for all types of changes to the data in your firebase database, add, removed, and changed
    // 2. (take action) a closures: when the change occurs, the database updates the app with the most recent data via the closure, which is passed an instance of FIRDataSnapshot,
    // Snapshot represents the data at that specific moment in time. To access the data n the snapshot, you use the value propertys
    
    // 1. attach a listener to receive updates whenever the grocery-items endpoint is modifieds
    ref.observe(.value, with: { snapshot in
      // 2. store the latest data in a local variable inside the listener's closure
      var newItems: [GroceryItem] = []
      
      // 3. the listener's closure returns a snapshot of the latest data. The snapshot contains the entire list of grocery items.
      //    Using children, you loop through the grocery items
      for item in snapshot.children{
        // 4. The GroceryItem struct has an initializer that populates its properties using a FIRDataSnapshot
        //    A snapshot value is of type AnyObject, and can be a dictionary, array, number, or string
        let groceryItem = GroceryItem(snapshot: item as! FIRDataSnapshot)
        newItems.append(groceryItem)
      }
      
      // 5. Reassign items to the latest version of the data, the reload the table view so it displays the latest versions
      self.items = newItems
      self.tableView.reloadData()
      //print(snapshot.value)
    })
    */
    
    // ***** Phase II Retrieving data and sort the items **********
    // Sorting the Grocery List
    // To sort the data by a key, use queryOrdered(byChild: fieldValue). For example, order by completed items
    ref.queryOrdered(byChild: "completed").observe(.value, with: { snapshot in
      var newItems: [GroceryItem] = []
      
      for item in snapshot.children {
        let groceryItem = GroceryItem(snapshot: item as! FIRDataSnapshot)
        newItems.append(groceryItem)
      }
      
      self.items = newItems
      self.tableView.reloadData()
    })
  
  }
  
  // MARK: UITableView Delegate methods
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return items.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath)
    let groceryItem = items[indexPath.row]
    
    cell.textLabel?.text = groceryItem.name
    cell.detailTextLabel?.text = groceryItem.addedByUser
    
    toggleCellCheckbox(cell, isCompleted: groceryItem.completed)
    
    return cell
  }
  
  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }
  
  
  // Check off items
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    //1 Find the cell that user tapped
    guard let cell = tableView.cellForRow(at: indexPath) else { return }
    // 2 Get the corresponding GroceryItem by using the index path's row
    let groceryItem = items[indexPath.row]
    // 3 Negate (否定）cmpleted on the grocery item to toggle the status
    let toggledCompletion = !groceryItem.completed
    
    // 4 Update the visual properties of the cell
    toggleCellCheckbox(cell, isCompleted: toggledCompletion)
    
    // is replaced
    /*
    groceryItem.completed = toggledCompletion
    tableView.reloadData()
    */
    // by 
    groceryItem.ref?.updateChildValues(["completed": toggledCompletion])
    // passing a dictionary to update filebase. 
    // The method is different from setValue() because it only applies updates, whereas setValue() is destructive and replacesthe entire value at that reference. 
    
    
  }
  
  func toggleCellCheckbox(_ cell: UITableViewCell, isCompleted: Bool) {
    if !isCompleted {
      cell.accessoryType = .none
      cell.textLabel?.textColor = UIColor.black
      cell.detailTextLabel?.textColor = UIColor.black
    } else {
      cell.accessoryType = .checkmark
      cell.textLabel?.textColor = UIColor.gray
      cell.detailTextLabel?.textColor = UIColor.gray
    }
  }
  
  // MARK: Delete item
  // commit after deleting
  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      
      //Remove items from table view only
      /*
      items.remove(at: indexPath.row)
      tableView.reloadData()
      */
      
      //Remove items from database permenantly and Firebase will update data in real-time
      let groceryItem = items[indexPath.row]
      
      // The line makes run-time error of image not found ??
      // groceryItem.ref?.removeValue()
      
      //instead, I refer to item in another way
      let itemref = ref.child(groceryItem.key)
      itemref.removeValue()
    }
  }
  
  // MARK: Add Item
  
  @IBAction func addButtonDidTouch(_ sender: AnyObject) {
    let alert = UIAlertController(title: "Grocery Item",
                                  message: "Add an Item",
                                  preferredStyle: .alert)
    
    let saveAction = UIAlertAction(title: "Save",
                                   style: .default) { action in
                                    
      // 1 get the text field (and its text) from the alert controller
      // original: let textField = alert.textFields![0]
      guard let UITextField = alert.textFields?.first,
        let text = UITextField.text else { return }
      
      // 2 Using the current users' data, create a new GroceryItem that is not completed by default
      //let groceryItem = GroceryItem(name: textField.text!,
      let groceryItem = GroceryItem(name: text,
                                    addedByUser: self.user.email,
                                    completed: false)
      
      // 3 create a child reference using child(_:)
      let groceryItemRef = self.ref.child(text.lowercased())
       
      // 4 use setValue(_:) to save data to the databases
      groceryItemRef.setValue(groceryItem.toAnyObject())
      
      /* obselete. While database is changed, Firebase will sync all users with latest data automatically
      self.items.append(groceryItem)
      self.tableView.reloadData()
      */
    }
    
    let cancelAction = UIAlertAction(title: "Cancel",
                                     style: .default)
    
    alert.addTextField()
    
    alert.addAction(saveAction)
    alert.addAction(cancelAction)
    
    present(alert, animated: true, completion: nil)
  }
  
  func userCountButtonDidTouch() {
    performSegue(withIdentifier: listToUsers, sender: nil)
  }
  
}
