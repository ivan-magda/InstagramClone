//
//  FeedTableViewController.swift
//  InstagramClone
//
//  Created by Иван Магда on 27.12.15.
//  Copyright © 2015 Ivan Magda. All rights reserved.
//

import UIKit
import Parse

class FeedTableViewController: UITableViewController {
    // MARK: - Properties
    
    private var imageFiles = [PFFile]()
    private var users = [String : String]()
    private var usernames = [String]()
    private var messages = [String]()

    // MARK: - View life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let getFollowedUsers = PFQuery(className: "Followers")
        getFollowedUsers.whereKey("follower", equalTo: PFUser.currentUser()!.objectId!)
        getFollowedUsers.findObjectsInBackgroundWithBlock() { (users, error) in
            if let error = error {
                print(error.localizedDescription)
            } else if let users = users {
                self.imageFiles.removeAll(keepCapacity: true)
                self.users.removeAll(keepCapacity: true)
                self.usernames.removeAll(keepCapacity: true)
                self.messages.removeAll(keepCapacity: true)
                
                for user in users {
                    let followedUserId = user["following"] as! String
                    
                    // Get username of the user.
                    PFUser.query()!.getObjectInBackgroundWithId(followedUserId) { (user, error) in
                        if let error = error {
                            print(error.localizedDescription)
                        } else if let user = user as? PFUser {
                            self.users[user.objectId!] = user.username!
                            
                            // Get posts of the user.
                            let followedUserPosts = PFQuery(className: "Post")
                            followedUserPosts.whereKey("userId", equalTo: followedUserId)
                            followedUserPosts.orderByDescending("createdAt")
                            followedUserPosts.findObjectsInBackgroundWithBlock() { (posts, error) in
                                if let error = error {
                                    print(error.localizedDescription)
                                } else if let posts = posts {
                                    for post in posts {
                                        self.usernames.append(user.username!)
                                        self.messages.append(post["message"] as! String)
                                        self.imageFiles.append(post["imageFile"] as! PFFile)
                                        
                                        dispatch_async(dispatch_get_main_queue()) {
                                            self.tableView.reloadData()
                                        }
                                    }
                                    
                                    debugPrint(self.users)
                                    debugPrint(self.messages)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usernames.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("FeedCell") as! FeedTableViewCell
        cell.postedImageView.image = UIImage(named: "placeholder.png")!
        cell.usernameLabel.text = usernames[indexPath.row]
        cell.messageLabel.text = messages[indexPath.row]
        
        weak var weakCell = cell
        imageFiles[indexPath.row].getDataInBackgroundWithBlock() { (imageData, error) in
            if let error = error {
                print(error.localizedDescription)
            } else if let imageData = imageData {
                weakCell?.postedImageView.image = UIImage(data: imageData)
            }
        }

        return cell
    }
    
    // MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 240.0
    }

}
