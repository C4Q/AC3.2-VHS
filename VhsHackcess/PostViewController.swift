//
//  PostViewController.swift
//  VhsHackcess
//
//  Created by Victor Zhong on 2/20/17.
//  Copyright © 2017 C4Q. All rights reserved.
//

import UIKit
import Firebase

class PostViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var commentView: UITextView!
    @IBOutlet weak var commentTableView: UITableView!
    @IBOutlet weak var replyField: UITextField!
    @IBOutlet weak var replyButton: UIButton!
    @IBOutlet weak var replyFieldBottomConstraint: NSLayoutConstraint!
    
    @IBAction func replyButtonTapped(_ sender: UIButton) {
        postComment()
    }
    
    var postString: String!
    var commmunityID: String!
    var databaseRef: FIRDatabaseReference!
    var commentRef: FIRDatabaseReference!
    var post = Post()
    var comments = [Comment]()
    var currentUser: FIRUser!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        commentTableView.delegate = self
        commentTableView.dataSource = self
        self.replyButton.isEnabled = false
        
        //color scheme
        self.titleLabel.textColor = ColorManager.shared.primary
        self.replyButton.tintColor = ColorManager.shared.primary
        
        replyField.delegate = self
        databaseRef = FIRDatabase.database().reference().child(commmunityID).child("posts").child(postString)
        commentRef = FIRDatabase.database().reference().child(commmunityID).child("post_comments").child(postString)
        populatePost()
        populateComments()
        checkLoggedIn()
        
        self.commentTableView.estimatedRowHeight = 150.0
        self.commentTableView.rowHeight = UITableViewAutomaticDimension
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
    }
    
    func populatePost() {
        titleLabel.text = post.title
        
        let attributedString = NSMutableAttributedString(string: "Submitted by: ", attributes: [NSFontAttributeName : UIFont.systemFont(ofSize: 14, weight: UIFontWeightLight)])
        let descriptionAttribute = NSMutableAttributedString(string: post.author, attributes: [NSForegroundColorAttributeName : ColorManager.shared.primary, NSFontAttributeName : UIFont.systemFont(ofSize: 14, weight: UIFontWeightBold)])
        attributedString.append(descriptionAttribute)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        
        let textLength = attributedString.string.characters.count
        let range = NSRange(location: 0, length: textLength)
        
        attributedString.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: range)
        
        idLabel.attributedText = attributedString
        commentView.text = post.body
    }
    
    func checkLoggedIn() {
        if let user = FIRAuth.auth()?.currentUser {
            currentUser = user
            replyButton.isEnabled = true
        }
    }
    
    func populateComments() {
        comments.removeAll()
        
        commentRef?.observeSingleEvent(of: .value , with: { (snapshot) in
            for child in snapshot.children {
                if let snap = child as? FIRDataSnapshot,
                    let valueDict = snap.value as? [String : Any] {
                    let comment = Comment(uid: valueDict["UID"] as! String,
                                          author: valueDict["Author"] as! String,
                                          text: valueDict["Text"] as! String)
                    self.comments.append(comment)
                }
            }
            
            self.commentTableView.reloadData()
        })
    }
    
    func postComment() {
        if let reply = replyField.text {
            replyButton.isEnabled = false
            
            let replyRef = commentRef.childByAutoId()
            let replyRefDict: [String : String] = [
                "Author" : (currentUser.email)!,
                "Text" : reply,
                "UID" : currentUser.uid
            ]
            replyRef.setValue(replyRefDict) { (error, reference) in
                if error != nil {
                    self.showOKAlert(title: "Error!", message: error?.localizedDescription)
                }
                else {
                    self.showOKAlert(title: "Message Posted!", message: nil, dismissCompletion: {
                        action in self.populateComments()
                    }, completion: {
                        self.replyField.text = ""
                    })
                }
            }
            self.replyButton.isEnabled = true
        }
    }

    
    func showOKAlert(title: String, message: String?, dismissCompletion: ((UIAlertAction) -> Void)? = nil, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .cancel, handler: dismissCompletion)
        alert.addAction(ok)
        self.present(alert, animated: true, completion: completion)
    }
    
    // MARK: - tableView Stuff
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseComment", for: indexPath) as! CommentTableViewCell
        cell.commentLabel?.text = comments[indexPath.row].text
        cell.user = comments[indexPath.row].author
        
        return cell
    }
    
    
     // MARK: - Textfield
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        if replyButton.isEnabled {
            replyButtonTapped(replyButton)
        }
        return true
    }
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
 
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardHeight = keyboardSize.height
            replyFieldBottomConstraint.isActive = false
            replyFieldBottomConstraint = replyField.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor, constant: -keyboardHeight - 8.0)
            replyFieldBottomConstraint.isActive = true
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        replyFieldBottomConstraint.isActive = false
        replyFieldBottomConstraint = replyField.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor, constant: -8.0)
        replyFieldBottomConstraint.isActive = true
    }
    
}
