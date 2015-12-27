//
//  PostImageViewController.swift
//  InstagramClone
//
//  Created by Иван Магда on 26.12.15.
//  Copyright © 2015 Ivan Magda. All rights reserved.
//

import UIKit
import Parse

class PostImageViewController: UIViewController {
    // MARK: - Properties
    
    @IBOutlet weak var imageToPost: UIImageView!
    @IBOutlet weak var message: UITextField!
    
    /// Image picker controller to let us take/pick photo.
    private var imagePickerController = UIImagePickerController()
    
    private var activityIndicator = UIActivityIndicatorView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.imagePickerController.delegate = self
    }
    
    // MARK: - Actions
    
    @IBAction func chooseImage(sender: AnyObject) {
        let actionSheet = UIAlertController(title: "Take or pick an photo", message: nil, preferredStyle: .ActionSheet)
        actionSheet.addAction(UIAlertAction(title: "Take photo", style: .Default, handler: { (action) in
            self.shootPhoto()
        }))
        actionSheet.addAction(UIAlertAction(title: "Pick photo", style: .Default, handler: { (action) in
            self.photoFromLibrary()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        self.presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    @IBAction func postImage(sender: AnyObject) {
        self.activityIndicator = UIActivityIndicatorView(frame: self.view.bounds)
        self.activityIndicator.backgroundColor = UIColor(white: 1.0, alpha: 0.5)
        self.activityIndicator.center = self.view.center
        self.activityIndicator.hidesWhenStopped = true
        self.activityIndicator.activityIndicatorViewStyle = .Gray
        self.view.addSubview(self.activityIndicator)
        self.activityIndicator.startAnimating()
        
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        
        let post = PFObject(className: "Post")
        post["message"] = message.text
        post["userId"] = PFUser.currentUser()!.objectId!
        
        let imageData = UIImageJPEGRepresentation(imageToPost.image!, 0.8)!
        let imageFile = PFFile(name: "image.png", data: imageData)
        post["imageFile"] = imageFile
        
        post.saveInBackgroundWithBlock() { (succeeded, error) in
            dispatch_async(dispatch_get_main_queue()) {
                UIApplication.sharedApplication().endIgnoringInteractionEvents()
                self.activityIndicator.stopAnimating()
                
                if !succeeded {
                    print(error?.localizedDescription)
                } else {
                    self.navigationItem.prompt = "Image posted"
                    
                    let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(2 * Double(NSEC_PER_SEC)))
                    dispatch_after(delayTime, dispatch_get_main_queue()) {
                        self.navigationItem.prompt = nil
                        self.imageToPost.image = UIImage(named: "placeholder.png")!
                    }
                }
            }
        }
    }
}

extension PostImageViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    private func noCamera() {
        let alertVC = UIAlertController(title: "No Camera", message: "Sorry, this device has no camera", preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "OK", style:.Default, handler: nil)
        alertVC.addAction(okAction)
        
        self.presentViewController(alertVC, animated: true, completion: nil)
    }
    
    /// Get a photo from the library.
    func photoFromLibrary() {
        imagePickerController.allowsEditing = false
        imagePickerController.sourceType = .PhotoLibrary
        
        self.presentViewController(imagePickerController, animated: true, completion: nil)
    }
    
    /// Take a picture, check if we have a camera first.
    func shootPhoto() {
        if UIImagePickerController.availableCaptureModesForCameraDevice(.Rear) != nil {
            imagePickerController.allowsEditing = false
            imagePickerController.sourceType = .Camera
            imagePickerController.cameraCaptureMode = .Photo
            
            self.presentViewController(imagePickerController, animated: true, completion: nil)
        } else {
            noCamera()
        }
    }
    
    // MARK: UIImagePickerControllerDelegate
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        dispatch_async(dispatch_get_main_queue()) {
            let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage
            self.imageToPost.image = pickedImage
            
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
