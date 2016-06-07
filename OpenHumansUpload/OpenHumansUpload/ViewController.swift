//
//  ViewController.swift
//  OpenHumansUpload
//
//  Created by James Turner on 4/28/16.
//  Copyright © 2016 Open Humans. All rights reserved.
//

import UIKit
import HealthKit
import Kanna

class ViewController: UIViewController {

    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var instructions: UILabel!
    var healthStore : HKHealthStore!
    
    @IBOutlet weak var webView: UIWebView!
    enum AppState {
        case Start, Checking, Prelogin, Postlogin
    }
    
    var currentState = AppState.Start
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.hidden = true
        instructions.text = "Welcome to the Open Humans Healthkit Intergrator"
        webView.layer.cornerRadius = 5
        webView.layer.borderWidth = 2
        webView.layer.borderColor = UIColor.blackColor().CGColor
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func validateToken(token: String) -> Void {
        
    }
    
    @IBAction func nextAction(sender: AnyObject) {
        switch currentState {
        case .Start:
            let prefs = NSUserDefaults.standardUserDefaults()
            if let token = prefs.stringForKey("oauth2_token") {
                instructions.text = "Authorizing..."
                validateToken(token)
            } else {
                instructions.text = "To begin, you need to authenticate your identity with the Open Humans Web Site."
                actionButton.setTitle("Go to Open Humans website", forState: .Normal)
                currentState = .Prelogin
            }
        case .Prelogin:
            webView.hidden = false;
            let url = NSURL (string: "https://www.openhumans.org/direct-sharing/projects/oauth2/authorize/?client_id=UnO6uvDitZ6K1sSSTfKQZ5Jgs5Zj0Tc58sXXI7qw&response_type=code");
            let requestObj = NSURLRequest(URL: url!);
            webView.loadRequest(requestObj);
        default:
            print("Ooops")
        }
    }
    
    func sendS3File () {
        //multipart/form-data; boundary=----WebKitFormBoundaryx74HehgeBaBNTFiu
        //------WebKitFormBoundaryx74HehgeBaBNTFiu
//        Content-Disposition: form-data; name="AWSAccessKeyId"
//        
//        AKIAIKNTFUJJTNS6N7HA
//        ------WebKitFormBoundaryx74HehgeBaBNTFiu
//        Content-Disposition: form-data; name="acl"
//        
//        private
//        ------WebKitFormBoundaryx74HehgeBaBNTFiu
//        Content-Disposition: form-data; name="Content-Type"
//        
//        binary/octet-stream
//        ------WebKitFormBoundaryx74HehgeBaBNTFiu
//        Content-Disposition: form-data; name="key"
//        
//        member-files/data_selfie/316c4c9c-0e47-11e6-8220-427c209ca999/${filename}
//        ------WebKitFormBoundaryx74HehgeBaBNTFiu
//        Content-Disposition: form-data; name="policy"
//        
//        eyJleHBpcmF0aW9uIjogIjIwMTYtMDQtMjlUMjA6NDY6MDFaIiwiY29uZGl0aW9ucyI6IFt7ImFjbCI6ICJwcml2YXRlIn0seyJidWNrZXQiOiAib3Blbi1odW1hbnMtcHJvZHVjdGlvbiJ9LFsic3RhcnRzLXdpdGgiLCAiJENvbnRlbnQtVHlwZSIsICIiXSxbInN0YXJ0cy13aXRoIiwgIiRrZXkiLCAibWVtYmVyLWZpbGVzL2RhdGFfc2VsZmllLzMxNmM0YzljLTBlNDctMTFlNi04MjIwLTQyN2MyMDljYTk5OS8iXSxbImVxIiwgIiRzdWNjZXNzX2FjdGlvbl9zdGF0dXMiLCAiMjAxIl1dfQ==
//        ------WebKitFormBoundaryx74HehgeBaBNTFiu
//        Content-Disposition: form-data; name="success_action_status"
//        
//        201
//        ------WebKitFormBoundaryx74HehgeBaBNTFiu
//        Content-Disposition: form-data; name="signature"
//        
//        ccn+pwqUPZ8SM/j/0gnMm6u4V2U=
//        ------WebKitFormBoundaryx74HehgeBaBNTFiu
//        Content-Disposition: form-data; name="file"; filename="test.txt"
//        Content-Type: text/plain
//        
//        
//        ------WebKitFormBoundaryx74HehgeBaBNTFiu--

        
    }
    
    @IBAction func uploadHealthkitData(sender: AnyObject) {
        if HKHealthStore.isHealthDataAvailable() {
            let healthStore = HKHealthStore()
            healthStore.requestAuthorizationToShareTypes([],
                                                         readTypes: [HKObjectType.workoutType(),
                HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierBloodType)!,
                HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierDateOfBirth)!,
                HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierBiologicalSex)!,
                HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierFitzpatrickSkinType)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeight)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierNikeFuel)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierUVExposure)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryIron)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryZinc)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodGlucose)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFiber)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietarySugar)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryWater)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierInhalerUsage)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierLeanBodyMass)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryBiotin)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCopper)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFolate)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryIodine)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryNiacin)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietarySodium)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryPhosphorus)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryChloride)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryChromium)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCalcium)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryProtein)!],
                                                         completion: { (success, error) in
                                                            let request = NSMutableURLRequest(URL: NSURL(string: "https://www.openhumans.org/account/login/?next=/activity/data-selfie/upload/")!)
                                                            let session = NSURLSession.sharedSession()
                                                            request.HTTPMethod = "GET"
                                                            let task = session.dataTaskWithRequest(request, completionHandler: {data, resp, error -> Void in
                                                                if let response = resp as? NSHTTPURLResponse {

                                                                    if let headerFields = response.allHeaderFields as? [String: String] {
                                                                        let cookies = NSHTTPCookie.cookiesWithResponseHeaderFields(headerFields, forURL: response.URL!)
                                                                        NSHTTPCookieStorage.sharedHTTPCookieStorage().setCookies(cookies, forURL: response.URL!, mainDocumentURL: nil)
                                                                        var token = "";
                                                                        for cookie in cookies {
                                                                            if (cookie.name == "csrftoken") {
                                                                                token = cookie.value;

                                                                            }
                                                                        }
                                                                        if (token != "") {
                                                                            NSLog("Token = %@", token)
                                                                            let request1 = NSMutableURLRequest(URL: NSURL(string: "https://www.openhumans.org/account/login/")!)
                                                                            request1.HTTPMethod = "POST"
                                                                            let body = "csrfmiddlewaretoken=" + token + "&next=/activity/data-selfie/upload/&username=blackbearnh&password=rplacA89"
                                                                            request1.HTTPBody = body.dataUsingEncoding(NSUTF8StringEncoding)
//                                                                            request1.addValue(token, forHTTPHeaderField: "X-CSRFToken");
                                                                            request1.addValue("application/multipart/form-data", forHTTPHeaderField: "Content-Type")
                                                                            request1.addValue("https://www.openhumans.org/account/login/?next=/activity/data-selfie/upload/", forHTTPHeaderField: "Referer")
//                                                                            request1.addValue("".stringByAppendingFormat("%d", body.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)), forHTTPHeaderField: "Content-Length")
                                                                            request1.addValue("text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8", forHTTPHeaderField: "Accept")
                                                                            let task1 = session.dataTaskWithRequest(request1, completionHandler: {data1, resp1, error -> Void in
                                                                                if let response1 = resp1 as? NSHTTPURLResponse {
                                                                                    NSLog("status = %d", response1.statusCode)
                                                                                    let responseData1 = String(data: data1!, encoding: NSUTF8StringEncoding)
                                                                                    if let doc = Kanna.HTML(html: responseData1!, encoding: NSUTF8StringEncoding) {
                                                                                        if let form = doc.at_xpath("//form[@id = 's3upload']") {
                                                                                            let action = form.xpath("@action").text
                                                                                            let hiddens = NSMutableDictionary()
                                                                                            for input in form.xpath(".//input[@type = 'hidden']") {
                                                                                                hiddens[(input.at_xpath("@name")?.text)!] = input.at_xpath("@value")?.text
                                                                                            }
                                                                                            let request2 = NSMutableURLRequest(URL: NSURL(string: action!)!)
                                                                                            request2.HTTPMethod = "POST"
                                                                                            let boundary = "----0xdeadbeefdeadbeefdeadbeef";
                                                                                            request2.addValue("multipart/form-data; boundary=" + boundary, forHTTPHeaderField: "Content-Type")
                                                                                            var body = NSMutableData()

                                                                                            for ele in hiddens.allKeys {
                                                                                                let key = ele as! String
                                                                                                let str = boundary + "\nContent=Disposition: form-data; name=\"" + key + "\"\r\n\r\n" + (hiddens[key] as! String) + "\r\n"
                                                                                                body.appendData(str.dataUsingEncoding(NSUTF8StringEncoding)!)
                                                                                            }
                                                                                            body.appendData("Content-Disposition: form-data; name=\"file\"; filename=\"iostest.txt\"\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
                                                                                            body.appendData("Content-Type: application/octet-stream\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
                                                                                            body.appendData("This is a test dump to see if it works\nDoes it?\n".dataUsingEncoding(NSUTF8StringEncoding)!)
                                                                                            
                                                                                            request2.HTTPBody = body
                                                                                            request2.addValue("".stringByAppendingFormat("%d", body.length), forHTTPHeaderField: "Content-Length")

                                                                                        }
                                                                                    }

                                                                                }
                                                                            })
                                                                            task1.resume()

                                                                        }
                                                                    }

                                                                }

                                                            })
                                                            
                                                            task.resume()

                                                            
            })
            
        }
    }

}

