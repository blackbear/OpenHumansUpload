//
//  OH-Oauth2.swift
//  OpenHumansUpload
//
//  Created by James Turner on 6/7/16.
//
/**
 
 The MIT License (MIT)
 
 Copyright (c) 2016 James M. Turner
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 
 **/

import Foundation
import UIKit

protocol OHOAuth2Client : class {
    func authenticateSucceeded(accessToken : String)
    func authenticateFailed()
    func authenticateCanceled()
}

let oauthsharedInstance = OH_OAuth2()

class OH_OAuth2 {
    
    static func sharedInstance() -> OH_OAuth2 {
        return oauthsharedInstance;
    }
    var wv_vc : ViewController?
    
    /// The username used to authenticate OAuth2 requests with the OpenHumans server. Found on the project page for your activity / study
    var ohClientId=""
    
    /// The password used to authenticate OAuth2 requests with the OpenHumans server. Found on the project page for your activity / study
    var ohSecretKey=""
    
    /// The URL scheme that has been registered for Open Humans with this activity / study
    var applicationURLScheme=""
    
    
    init() {
        if let path = NSBundle.mainBundle().pathForResource("OhSettings", ofType: "plist"), dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject] {
            ohSecretKey = dict["oh_client_secret"] as! String
            ohClientId = dict["oh_client_id"] as! String
            applicationURLScheme = dict["oh_url_prefix"] as! String
        }
    }
    
    enum GrantType {
        case Authorize, Refresh
    }
    
    /// This function should be called from the `openURL` handler of your application to intercept and handle
    /// Open Humans OAuth2 callbacks. If it returns true, the URL was handled and no further processing of the
    /// URL should be attempted.
    
    func parseLaunchURL(url : NSURL) -> Bool {
        let components = NSURLComponents.init(URL: url, resolvingAgainstBaseURL: false)
        if components?.scheme != applicationURLScheme {
            return false;
        }
        if let queryItems = components?.queryItems {
            for queryItem in queryItems {
                if queryItem.name == "code" {
                    self.sendTokenRequestWithToken(queryItem.value!, grantType: GrantType.Authorize);
                }
            }
        }
        return true;
    }
    typealias JSON = AnyObject
    typealias JSONDictionary = Dictionary<String, JSON>
    typealias JSONArray = Array<JSON>
    
    func processResponse(data : NSData?, error: NSError?) -> Void {
        if (error != nil) {
            for client in self.subscribers {
                client.authenticateFailed();
            }
            return;
            
        }
        
        do {
            var json = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions()) as? JSONDictionary
            let accessToken = json!["access_token"] as! String
            let refreshToken = json!["refresh_token"] as! String
            let prefs = NSUserDefaults.standardUserDefaults()
            prefs.setValue(refreshToken, forKeyPath:"oauth2_refresh_token")
            
            for client in self.subscribers {
                client.authenticateSucceeded(accessToken)
            }
            
        } catch {
            print(error)
        }
        
    }
    
    func sendTokenRequestWithToken(token : String, grantType : GrantType) -> Void {
        var reqString = "";
        switch (grantType) {
        case GrantType.Authorize:
            reqString = "grant_type=authorization_code&code=" + token + "&redirect_uri=" + self.applicationURLScheme + "://";
        case GrantType.Refresh:
            reqString = "grant_type=refresh_token&refresh_token=" + token + "&redirect_uri=" + self.applicationURLScheme + "://";
        }
        let request = NSMutableURLRequest(URL: NSURL(string: "https://www.openhumans.org/oauth2/token/")!)
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "POST"
        let loginString = NSString(format: "%@:%@", ohClientId, ohSecretKey)
        let loginData: NSData = loginString.dataUsingEncoding(NSUTF8StringEncoding)!
        let base64LoginString = loginData.base64EncodedStringWithOptions([])
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        request.HTTPBody = reqString.dataUsingEncoding(NSUTF8StringEncoding)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            var respString = String(data, NSUTF8StringEncoding)
            print(respString)
            if self.wv_vc != nil {
                self.wv_vc?.dismissViewControllerAnimated(true,completion: {
                    self.processResponse(data, error:error);
                });
            } else {
                self.processResponse(data, error:error);
            }
        });
        
        task.resume()
    }
    
    
    var subscribers: [OHOAuth2Client] = Array();
    func subscribeToEvents(listener: OHOAuth2Client) {
        unsubscribeToEvents(listener)
        subscribers.append(listener)
    }
    
    func unsubscribeToEvents(listener: OHOAuth2Client) {
        subscribers = subscribers.filter() { $0  !== listener }
    }
    
    func authenticateOAuth2<C1: ViewController where C1:OHOAuth2Client>(vc:C1) -> Void {
        
        let prefs = NSUserDefaults.standardUserDefaults()
        if let token = prefs.stringForKey("oauth2_refresh_token") {
            sendTokenRequestWithToken(token, grantType: GrantType.Refresh)
        } else {
            let url = NSURL (string: "https://www.openhumans.org/direct-sharing/projects/oauth2/authorize/?client_id=" + ohClientId + "&response_type=code");
            let requestObj = NSURLRequest(URL: url!);
            wv_vc = ViewController()
            wv_vc!.view = UIView(frame:(vc.view.frame))
            let wv = UIWebView(frame: vc.view.frame)
            wv_vc!.view.addSubview(wv)
            vc.presentViewController(wv_vc!, animated: true, completion: {
                wv.loadRequest(requestObj);
            });
            
        }
        
    }
}
