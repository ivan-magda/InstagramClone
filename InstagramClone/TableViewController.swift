//
//  TableViewController.swift
//  InstagramClone
//
//  Created by Иван Магда on 26.12.15.
//  Copyright © 2015 Ivan Magda. All rights reserved.
//

import UIKit
import Parse

class TableViewController: UITableViewController {
    // MARK: - Properties
    
    private var usernames = [String]()
    private var userIds = [String]()
    private var isFollowing = [String : Bool]()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Enable pull to refresh.
        self.refreshControl = UIRefreshControl()
        self.refreshControl!.addTarget(self, action: Selector("refresh"), forControlEvents: .ValueChanged)
        
        refresh()
    }
    
    // MARK: - Private
    
    func refresh() {
        // Getting all users, ordered ascending by its username.
        let query = PFUser.query()?.orderByAscending("username")
        
        var networkOnlyCachePolicy = false
        if usernames.count == 0 || userIds.count == 0 || isFollowing.count == 0 {
            networkOnlyCachePolicy = false
            query?.cachePolicy = .CacheThenNetwork
        } else {
            networkOnlyCachePolicy = true
            query?.cachePolicy = .NetworkOnly
        }
        
        query?.findObjectsInBackgroundWithBlock() { (users, error) in
            if error != nil {
                print(error?.localizedDescription)
            } else if let users = users as? [PFUser] {
                self.usernames.removeAll(keepCapacity: true)
                self.userIds.removeAll(keepCapacity: true)
                self.isFollowing.removeAll(keepCapacity: true)
                
                for user in users {
                    // Adding users dats to source data arrays.
                    if user.objectId != PFUser.currentUser()?.objectId {
                        self.usernames.append(user.username!)
                        self.userIds.append(user.objectId!)
                        
                        // Find users that current user following.
                        let follwingQuery = PFQuery(className: "Followers")
                        follwingQuery.whereKey("follower", equalTo: PFUser.currentUser()!.objectId!)
                        follwingQuery.whereKey("following", equalTo: user.objectId!)
                        
                        if networkOnlyCachePolicy {
                            follwingQuery.cachePolicy = .NetworkOnly
                        } else {
                            follwingQuery.cachePolicy = .CacheThenNetwork
                        }
                        
                        // If user following smb, then adding following user id and positive bool value
                        // to the isFollowing dictionary.
                        follwingQuery.findObjectsInBackgroundWithBlock() { (users, error) in
                            if error != nil {
                                print(error?.localizedDescription)
                            } else if users != nil && users!.count > 0 {
                                self.isFollowing[user.objectId!] = true
                            } else {
                                self.isFollowing[user.objectId!] = false
                            }
                            
                            // We are done here.
                            if self.isFollowing.count == self.usernames.count {
                                dispatch_async(dispatch_get_main_queue()) {
                                    self.tableView.reloadData()
                                    self.refreshControl?.endRefreshing()
                                }
                            }
                        }
                    }
                }
            }
            
            print(self.usernames)
            print(self.userIds)
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usernames.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell")!
        cell.textLabel?.text = usernames[indexPath.row]
        
        if isFollowing[userIds[indexPath.row]] == true {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }
        
        return cell
    }
    
    // MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("Did select user: \(usernames[indexPath.row])")
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let selectedUserId = userIds[indexPath.row]
        
        // Not following, need to follow new user, else unfollow.
        if isFollowing[selectedUserId] == false {
            isFollowing[selectedUserId] = true
            
            let following = PFObject(className: "Followers")
            following["following"] = userIds[indexPath.row]
            following["follower"] = PFUser.currentUser()!.objectId
            following.saveInBackgroundWithBlock() { (succeeded, error) in
                if !succeeded {
                    print("Failed to save follower: \(error?.localizedDescription)")
                } else {
                    dispatch_async(dispatch_get_main_queue()) {
                        let cell = tableView.cellForRowAtIndexPath(indexPath)!
                        cell.accessoryType = .Checkmark
                    }
                }
            }
        } else {
            isFollowing[selectedUserId] = false
            
            let unfollowQuery = PFQuery(className: "Followers")
            unfollowQuery.whereKey("follower", equalTo: PFUser.currentUser()!.objectId!)
            unfollowQuery.whereKey("following", equalTo: userIds[indexPath.row])
            
            unfollowQuery.findObjectsInBackgroundWithBlock() { (users, error) in
                if error != nil {
                    print(error?.localizedDescription)
                } else if let users = users {
                    assert(users.count == 1)
                    
                    users[users.count - 1].deleteInBackgroundWithBlock() { (succeeded, error) in
                        if !succeeded {
                            print(error?.localizedDescription)
                        } else {
                            dispatch_async(dispatch_get_main_queue()) {
                                let cell = tableView.cellForRowAtIndexPath(indexPath)!
                                cell.accessoryType = .None
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    }
}
