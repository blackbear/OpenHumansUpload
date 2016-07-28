//
//  ViewController.swift
//  OpenHumansUpload
//
//  Created by James Turner on 4/28/16.
//  Copyright © 2016 Open Humans. All rights reserved.
//

import UIKit
import HealthKit
import Foundation

class ViewController: UIViewController {

    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var instructions: UILabel!
    var healthStore : HKHealthStore!
    
    var accessToken = ""
    
    var fileList : JSONArray = JSONArray()
    
    enum AppState {
        case Start, Checking, Prelogin, Postlogin
    }
    
    var currentState = AppState.Start
    
    override func viewDidLoad() {
        super.viewDidLoad()
        instructions.hidden = true
        actionButton.hidden = true
        let oauth = OH_OAuth2.sharedInstance();
        if oauth.hasCachedToken() {
            instructions.text = "Logging in..."
            instructions.hidden = false
           
            OH_OAuth2.sharedInstance().authenticateOAuth2(self, allowLogin: false, handler: { (status : AuthorizationStatus) -> Void in
                if (status == AuthorizationStatus.AUTHORIZED) {
                    OH_OAuth2.sharedInstance().getMemberInfo({ (memberId, messagePermission, usernameShared, username, files) in
                        self.fileList = files
                        dispatch_async(dispatch_get_main_queue(), { 
                            self.performSegueWithIdentifier("startupToMain", sender: self)
                        })
                        }, onFailure: {
                            dispatch_async(dispatch_get_main_queue(), { 
                                self.authenticateRequiresLogin()
                            })
                            
                    })
                } else {
                    self.authenticateRequiresLogin()
                }
                
            });
        } else {
            self.authenticateRequiresLogin()
        }
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "startupToMain") {
            var vc = segue.destinationViewController as! MainMenu
            vc.fileList = fileList
        }
    }
    
    
    func authenticateRequiresLogin() {
        instructions.text = "Welcome to the Open Humans HealthKit Uploader. This tool will allow you to upload your HealthKit data (visible in the Health app) to your Open Humans account so that researchers can access the information you have recorded on your device.\n\nTo begin, you need to authenticate your identity with the Open Humans Web Site."
        actionButton.setTitle("Go to Open Humans website", forState: .Normal)
        instructions.hidden = false
        actionButton.hidden = false
    }
    
    func uploadSucceeded(res: String) {
        print(res);
    }
    func memberInfoFailed() {
        
    }

    func authenticateFailed() -> Void {
        authenticateRequiresLogin()
    }

    func authenticateCanceled() -> Void {
        authenticateRequiresLogin()
    }


    override func viewDidAppear(animated: Bool) {
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func validateToken(token: String) -> Void {
        
    }
    
    @IBAction func nextAction(sender: AnyObject) {
        OH_OAuth2.sharedInstance().authenticateOAuth2(self, allowLogin: true, handler: { (status : AuthorizationStatus) -> Void in
            OH_OAuth2.sharedInstance().getMemberInfo({ (memberId, messagePermission, usernameShared, username, files) in
                self.performSegueWithIdentifier("startupToMain", sender: self)
                }, onFailure: {
                    self.authenticateRequiresLogin()
            })
            
        });
    }
    

}

