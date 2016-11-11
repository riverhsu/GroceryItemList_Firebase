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

class OnlineUsersTableViewController: UITableViewController {
  
  // MARK: Constants
  let userCell = "UserCell"
  
  // MARK: Properties
  var currentUsers: [String] = []
  
  // Displaying a list of Online Users
  let usersRef = FIRDatabase.database().reference(withPath: "online")
  
  // MARK: UIViewController Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let vAuth = FIRAuth.auth()!
    if let uemail = vAuth.currentUser?.email{
        let msgstr = uemail + " is on line"
        let msgbox = UIAlertController(title: "Check", message: msgstr, preferredStyle: .alert)
        let okbtn = UIAlertAction(title: "OK", style: .default, handler: nil)
        msgbox.addAction(okbtn)
        self.present(msgbox, animated: true, completion: nil)
    }
    // Displaying a list of Online Users
    // currentUsers.append("hungry@person.food")   //oringally hard-coding here
    // *** append users ***
    // get reference from Firebase/online table to refresh here
    // 1. Create an observer that listens for children added to the location managed by usersRef
    //    This is different than a value listner because only the added child is passed to the closure
    //    usersRef.observe(<#T##eventType: FIRDataEventType##FIRDataEventType#>, with: <#T##(FIRDataSnapshot) -> Void#>)
    
    usersRef.observe(.childAdded, with: { snap in
      // 2. Take the value from the snapshot, and hen append it to the local array
      guard let email = snap.value as? String else {return}
      self.currentUsers.append(email)
      // 3 The current row is always the count of the local array minus one because the indexes managed by the table view are zero-based
      let row = self.currentUsers.count - 1
      // 4. Create an instance NSIndexPath using the calculated row index
      let indexPath = IndexPath(row: row, section: 0)
      // 5. Insert the row using an animation that causes the cell to be inserted from the top
      self.tableView.insertRows(at: [indexPath], with: .top)
    })
    
    // *** while a user's offline ***
    usersRef.observe(.childRemoved, with: { snap in
      guard let emailToFind = snap.value as? String else {return}
      for (index, email) in self.currentUsers.enumerated(){
        if email == emailToFind {
          let indexPath = IndexPath(row: index, section: 0)
          self.tableView.deleteRows(at: [indexPath], with: .fade)
          self.currentUsers.remove(at: index)
        }
      }
    })
    
  }
  
  // MARK: UITableView Delegate methods
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return currentUsers.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: userCell, for: indexPath)
    let onlineUserEmail = currentUsers[indexPath.row]
    cell.textLabel?.text = onlineUserEmail
    return cell
  }
  
  // MARK: Actions
  
  @IBAction func signoutButtonPressed(_ sender: AnyObject) {
    //try! FIRAuth.auth()!.signOut()   //無效
    
    //Get the current signed-in user
    // let cuser = FIRAuth.auth()!.currentUser
    FIRAuth.auth()!.addStateDidChangeListener(){ auth, user in
      do {
        // it will take about 20 seconds for this listener to send out notification to Firebase
        try auth.signOut()
        self.dismiss(animated: true, completion: nil)
      } catch {

      }
    }
  }
}
