//
//  ViewController.swift
//  MemeMeImagePicker
//
//  Created by Steve Henderson on 2016-05-13.
//  Copyright © 2016 Steve Henderson. All rights reserved.
//

import UIKit

struct Meme {
    let topText:String
    let bottomText:String
    let image:UIImage
    let memedImage:UIImage
    
    init(topText: String, bottomText: String, image: UIImage, memedImage: UIImage) {
        self.topText = topText
        self.bottomText = bottomText
        self.image = image
        self.memedImage = memedImage
    }
}

class ViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var topTextField: UITextField!
    @IBOutlet weak var bottomTextField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        topTextField.delegate = self
        bottomTextField.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillDisappear(animated)
        cameraButton.enabled = UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)
        
        setupUI()
        subscribeToKeyboardNotifications()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        unsubscribeFromKeyboardNotifications()
    }
    
    // MARK: Meme Model methods
    func save() {
        let meme = Meme(topText: self.topTextField.text!, bottomText: self.bottomTextField.text!, image: self.imageView.image!, memedImage: generateMemedImage())
        
        // should save the meme here
        UIImageWriteToSavedPhotosAlbum(meme.memedImage, nil, nil, nil)
        
        // prompt user to share
        shouldShareMeme(meme)
    }
    
    func generateMemedImage() -> UIImage {
        // Hide toolbar
        self.toolBar.hidden = true
        
        // Render view to an image
        UIGraphicsBeginImageContext(self.view.frame.size)
        view.drawViewHierarchyInRect(self.view.frame, afterScreenUpdates: true)
        let memedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Show toolbar
        self.toolBar.hidden = false
        
        return memedImage
    }
    
    // MARK: UI Methods
    
    func shouldShareMeme(meme:Meme) {
        let alert = UIAlertController(title: "Share", message: "Would you like to share this Meme", preferredStyle: .Alert)
        let ok = UIAlertAction(title: "Ok", style: .Default) { (action:UIAlertAction!) in
            print("Should share meme")
            self.shareMeme(meme)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .Cancel) { (_:UIAlertAction!) in
            print("Cancelled")
        }
        
        alert.addAction(ok)
        alert.addAction(cancel)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func shareMeme(meme:Meme) {
        let activity = UIActivityViewController(activityItems: [meme.memedImage], applicationActivities: nil)
        presentViewController(activity, animated: true, completion: {
            self.resetUI()
        })
    }
    
    func resetUI() {
        self.view.endEditing(true)
        self.saveButton.enabled = false
        self.topTextField.text = ""
        self.bottomTextField.text = ""
        self.imageView.image = nil
    }
    
    func setupUI() {
        let memeTextAttr = [
            NSStrokeColorAttributeName: UIColor.blackColor(),
            NSForegroundColorAttributeName: UIColor.whiteColor(),
            NSFontAttributeName: UIFont(name: "HelveticaNeue-CondensedBlack", size: 36)!,
            NSStrokeWidthAttributeName: -3.0
        ]
        
        topTextField.defaultTextAttributes = memeTextAttr
        bottomTextField.defaultTextAttributes = memeTextAttr
        topTextField.attributedPlaceholder = NSAttributedString(string: "TOP", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor()])
        bottomTextField.attributedPlaceholder = NSAttributedString(string: "BOTTOM", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor()])
        topTextField.textAlignment = .Center
        bottomTextField.textAlignment = .Center
    }
    
    // MARK: Notifications

    func subscribeToKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.keyboardWillHide(_:)), name: UIKeyboardWillShowNotification, object: nil)
    }
    
    func unsubscribeFromKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        self.view.frame.origin.y -= getKeyboardHeight(notification)
    }
    
    func keyboardWillHide(notification: NSNotification) {
        self.view.frame.origin.y += getKeyboardHeight(notification)
    }
    
    // MARK: Misc methods
    func getKeyboardHeight(notification: NSNotification) -> CGFloat{
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue // of CGRect
        return keyboardSize.CGRectValue().height
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldDidBeginEditing(textField: UITextField) {
        textField.text = ""
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
    
    // MARK: UIImagePickerControllerDelegate
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imageView.image = image
        }
        
        dismissViewControllerAnimated(true, completion: {
            self.saveButton.enabled = true
        })
    }
    
    // MARK: IBAction
    @IBAction func pickAnImage(sender: AnyObject) {
        let picker = UIImagePickerController()
        picker.delegate = self;
        presentViewController(picker, animated: true, completion: nil)
    }
    
    @IBAction func pickAnImageFromCamera(sender: AnyObject) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = UIImagePickerControllerSourceType.Camera
        
        presentViewController(picker, animated: true, completion: nil)
    }
    
    @IBAction func saveButtonTapped(sender: AnyObject) {
        save()
    }
}

