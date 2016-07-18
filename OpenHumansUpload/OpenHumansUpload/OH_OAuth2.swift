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
import SafariServices

typealias JSON = AnyObject
typealias JSONDictionary = Dictionary<String, JSON>
typealias JSONArray = Array<JSON>

class PopupWebViewController : ViewController {
    var previousViewController : ViewController?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName:nibNameOrNil, bundle:nibBundleOrNil )
    }
}

enum AuthorizationStatus {
    case AUTHORIZED
    case CANCELED
    case FAILED
    case REQUIRES_LOGIN
}

let oauthsharedInstance = OH_OAuth2()

class OH_OAuth2 : NSObject, SFSafariViewControllerDelegate {
    
    static func sharedInstance() -> OH_OAuth2 {
        return oauthsharedInstance;
    }
    var wv_vc : SFSafariViewController?
    
    var memberId : String?
    
    /// The username used to authenticate OAuth2 requests with the OpenHumans server. Found on the project page for your activity / study
    var ohClientId=""
    
    /// The password used to authenticate OAuth2 requests with the OpenHumans server. Found on the project page for your activity / study
    var ohSecretKey=""
    
    /// The URL scheme that has been registered for Open Humans with this activity / study
    var applicationURLScheme=""
    
    
    override init() {
        super.init()
        if let path = NSBundle.mainBundle().pathForResource("OhSettings", ofType: "plist"), dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject] {
            ohSecretKey = dict["oh_client_secret"] as! String
            ohClientId = dict["oh_client_id"] as! String
            applicationURLScheme = dict["oh_url_prefix"] as! String
        }
    }
    
    enum GrantType {
        case Authorize, Refresh
    }
    
    /// Get member info from token
    ///
    func getMemberInfo(onSuccess: (memberId : String, messagePermission : Bool, usernameShared : Bool, username : String?, files: JSONArray) -> Void, onFailure:() ->Void) -> Void {
        let prefs = NSUserDefaults.standardUserDefaults()
        let accessToken = prefs.stringForKey("oauth2_access_token")
        let request = NSMutableURLRequest(URL: NSURL (string: "https://www.openhumans.org/api/direct-sharing/project/exchange-member/?access_token=" + accessToken!)!)
        let loginString = NSString(format: "%@:%@", ohClientId, ohSecretKey)
        let loginData: NSData = loginString.dataUsingEncoding(NSUTF8StringEncoding)!
        let base64LoginString = loginData.base64EncodedStringWithOptions([])
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")

        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "GET"
        
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            do {
                var htresponse = response as! NSHTTPURLResponse
                if (htresponse.statusCode != 200) {
                    onFailure()
                }
                var jsonString = String(data: data!, encoding: NSUTF8StringEncoding)
                var json = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions()) as? JSONDictionary
                if (json != nil) {
                    if (json!["project_member_id"] != nil) {
                        self.memberId = json!["project_member_id"] as! String
                        let messagePermission = json!["message_permission"] as! Bool
                        let usernameShared = json!["username_shared"] as! Bool
                        let fileList = json!["data"] as! JSONArray
//                let sources_shared = json!["sources_shared"] as! Dictionary
                        let username = json!["username"] as? String
                        onSuccess(memberId: self.memberId!, messagePermission: messagePermission, usernameShared: usernameShared, username: username, files:fileList)
                        return
                    }
                }
                onFailure()
                
            } catch {
                print(error)
            }

        });
        task.resume()

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
    
    func processResponse(data : NSData?, error: NSError?, grantType : GrantType) -> Void {
        if (error != nil) {
            for client in self.subscribers {
                self.clearCachedToken()
                if grantType == .Refresh {
                    client(status: AuthorizationStatus.REQUIRES_LOGIN)
                } else {
                    client(status: AuthorizationStatus.FAILED)
                }
            }
            self.subscribers.removeAll()

            return;
            
        }
        
        do {
            var json = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions()) as? JSONDictionary
            let accessToken = json!["access_token"] as! String
            let refreshToken = json!["refresh_token"] as! String
            let prefs = NSUserDefaults.standardUserDefaults()
            prefs.setValue(refreshToken, forKeyPath:"oauth2_refresh_token")
            prefs.setValue(accessToken, forKeyPath:"oauth2_access_token")
            for client in self.subscribers {
                client(status: AuthorizationStatus.AUTHORIZED)
            }
            self.subscribers.removeAll()
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
        
        request.HTTPBody = reqString.dataUsingEncoding(NSUTF8StringEncoding)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            if let wv = self.wv_vc {
                dispatch_async(dispatch_get_main_queue(), { 
                    self.wv_vc?.dismissViewControllerAnimated(true, completion: {
                        self.processResponse(data, error:error, grantType:grantType)
                    })
                })
            } else {
                let httpResponse = response as! NSHTTPURLResponse
                if httpResponse.statusCode == 401 {
                    self.clearCachedToken()
                    for client in self.subscribers {
                        if grantType == .Refresh {
                            client(status: AuthorizationStatus.REQUIRES_LOGIN)
                        } else {
                            client(status: AuthorizationStatus.FAILED)
                        }
                    }
                    self.subscribers.removeAll()
                }
                self.processResponse(data, error:error, grantType:grantType);
            }
        });
        
        task.resume()
    }
    
    
    var subscribers: [(status: AuthorizationStatus) -> Void] = Array();
    func subscribeToEvents(listener: (status: AuthorizationStatus) -> Void) {
        subscribers.append(listener)
    }
    
  
    func hasCachedToken() -> Bool {
        let prefs = NSUserDefaults.standardUserDefaults()
        return prefs.stringForKey("oauth2_refresh_token") != nil
    }

    func clearCachedToken() -> Void {
        let prefs = NSUserDefaults.standardUserDefaults()
        prefs.removeObjectForKey("oauth2_refresh_token")
        prefs.removeObjectForKey("oauth2_access_token")
    }

    func closeWeb () -> Void {
        if self.wv_vc != nil {
            self.wv_vc?.dismissViewControllerAnimated(true, completion: { 
                for client in self.subscribers {
                    client(status: AuthorizationStatus.CANCELED)
                }
            })
        } else {
            for client in self.subscribers {
                client(status: AuthorizationStatus.CANCELED)
            }
            
        }
        self.subscribers.removeAll()
        self.wv_vc = nil;
    }
    
    func safariViewControllerDidFinish(controller: SFSafariViewController)
    {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func authenticateOAuth2(vc:ViewController, allowLogin:Bool, handler:(status: AuthorizationStatus)->Void) -> Void {
        subscribers.append(handler)
        let prefs = NSUserDefaults.standardUserDefaults()
        if let token = prefs.stringForKey("oauth2_refresh_token") {
            sendTokenRequestWithToken(token, grantType: GrantType.Refresh)
            return
        }
        if allowLogin {
            let url = NSURL (string: "https://www.openhumans.org/direct-sharing/projects/oauth2/authorize/?client_id=" + ohClientId + "&response_type=code");
            self.wv_vc = SFSafariViewController(URL: url!);
            vc.presentViewController(self.wv_vc!, animated: true, completion: nil)
            
        } else {
            handler(status: AuthorizationStatus.REQUIRES_LOGIN)
        }
        
    }
    
    func deleteFile(id : NSNumber, handler:(success: Bool) -> Void) {
        let prefs = NSUserDefaults.standardUserDefaults()
        let accessToken = prefs.stringForKey("oauth2_access_token")
        let reqString = "https://www.openhumans.org/api/direct-sharing/project/files/delete/?access_token=" + accessToken!;
        let request = NSMutableURLRequest(URL: NSURL(string: reqString)!)
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "POST"
        let loginString = NSString(format: "%@:%@", ohClientId, ohSecretKey)
        let loginData: NSData = loginString.dataUsingEncoding(NSUTF8StringEncoding)!
        let base64LoginString = loginData.base64EncodedStringWithOptions([])
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let httpBody = "{\"project_member_id\": \"" + self.memberId! + "\", \"file_id\": " + id.stringValue + "}"
        request.HTTPBody = httpBody.dataUsingEncoding(NSUTF8StringEncoding)
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = session.dataTaskWithRequest(request, completionHandler: {data1, response, error -> Void in
            let httpResponse = response as! NSHTTPURLResponse
            if httpResponse.statusCode != 200 {
                handler(success: false)
                return
            }
            handler(success:true)
        });
        
        task.resume()
        
       
    }
    
    func uploadFile(fileName : String, data : String, memberId : String, handler:(success: Bool, filename: String?) -> Void) -> Void {
        let prefs = NSUserDefaults.standardUserDefaults()
        let accessToken = prefs.stringForKey("oauth2_access_token")
        let reqString = "https://www.openhumans.org/api/direct-sharing/project/files/upload/?access_token=" + accessToken!;
        let request = NSMutableURLRequest(URL: NSURL(string: reqString)!)
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "POST"
        let loginString = NSString(format: "%@:%@", ohClientId, ohSecretKey)
        let loginData: NSData = loginString.dataUsingEncoding(NSUTF8StringEncoding)!
        let base64LoginString = loginData.base64EncodedStringWithOptions([])
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=60b1416fed664815a28bf8be840458ae", forHTTPHeaderField: "Content-Type")
        let httpBody = "--60b1416fed664815a28bf8be840458ae\r\n" +
                        "Content-Disposition: form-data; name=\"project_member_id\"\r\n\r\n" +
                        memberId +
                        "\r\n--60b1416fed664815a28bf8be840458ae\r\n" +
                        "Content-Disposition: form-data; name=\"metadata\"\r\n\r\n" +
        "{\"tags\": [\"healthkit\",\"json\"], \"description\": \"JSON dump of Healthkit Data\"}\r\n" +
                        "--60b1416fed664815a28bf8be840458ae\r\n" +
                        "Content-Disposition: form-data; name=\"data_file\"; filename=\"" + fileName + "\"\r\n\r\n" + data +
                        "\r\n\r\n--60b1416fed664815a28bf8be840458ae--\r\n"
        request.HTTPBody = httpBody.dataUsingEncoding(NSUTF8StringEncoding)
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = session.dataTaskWithRequest(request, completionHandler: {data1, response, error -> Void in
            let httpResponse = response as! NSHTTPURLResponse
            if httpResponse.statusCode != 201 {
                handler(success: false, filename: nil)
                return
            }
            handler(success:true, filename: String(data: data1!, encoding: NSUTF8StringEncoding)!)
        });
        
        task.resume()

    }
}
