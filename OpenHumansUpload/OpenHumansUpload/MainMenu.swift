//
//  MainMenu.swift
//  OpenHumansUpload
//
//  Created by James Turner on 6/18/16.
//  Copyright © 2016 Open Humans. All rights reserved.
//

import UIKit
import HealthKitSampleGenerator
import HealthKitUI

class MainMenu: UIViewController {
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var uploadButton: UIButton!
    
    @IBOutlet weak var editUploadButton: UIButton!
    
    var fileList : JSONArray = JSONArray()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateDisplay()
        // Do any additional setup after loading the view.
    }

    func updateDisplay() {
        uploadButton.userInteractionEnabled = true
        if fileList.count == 0 {
            editUploadButton.hidden = true
        } else {
            editUploadButton.hidden = false
        }
        
    }
    
    @IBOutlet weak var progressView: UIProgressView!
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
    }

    @IBAction func selectData(sender: UIButton) {
    }
    
    @IBAction func editUploaded(sender: AnyObject) {
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "menuToFileList" {
            let vc = segue.destinationViewController as! DataFileView
            vc.dataFiles = self.fileList
        }
        if segue.identifier == "mainMenuToUpload" {
            let vc = segue.destinationViewController as! ExportMenu
            vc.fileList = self.fileList
        }
        
        
    }
    
    @IBAction func uploadIncremental(sender: AnyObject) {
        uploadButton.userInteractionEnabled = false
        activityIndicator.startAnimating()
        let defs = NSUserDefaults.standardUserDefaults()
        let lastDate = defs.objectForKey("lastSaveDate") as! NSDate?
        defs.setObject(NSDate(), forKey: "lastSaveDate")
        let configuration   = HealthDataFullExportConfiguration(profileName: "Profilname", exportType: HealthDataToExportType.ALL, startDate: lastDate, endDate: NSDate())
        let target = JsonSingleDocInMemExportTarget()
        self.progressView.progress = 0
        self.progressView.hidden = false
        // create your instance of HKHeakthStore
        let healthStore     = HKHealthStore()
        // and pass it to the HealthKitDataExporter
        let exporter        = HealthKitDataExporter(healthStore: healthStore)
        exporter.export(
            
            exportTargets: [target],
            
            exportConfiguration: configuration,
            
            onProgress: {
                (message: String, progressInPercent: NSNumber?) -> Void in
                // output progress messages
                dispatch_async(dispatch_get_main_queue(), {
                    self.progressView.progress = (progressInPercent?.floatValue)! / 100.0
                })
            },
            
            onCompletion: {
                (error: ErrorType?)-> Void in
                // output the result - if error is nil. everything went well
                if let exportError = error {
                    print(exportError)
                } else {
                    let dayTimePeriodFormatter = NSDateFormatter()
                    dayTimePeriodFormatter.dateFormat = "yyyy-MM-dd"
                    let fname = "healthkit-export_" + dayTimePeriodFormatter.stringFromDate(NSDate()) + ".json"
                    OH_OAuth2.sharedInstance().uploadFile(fname, data: target.getJsonString(), memberId: OH_OAuth2.sharedInstance().memberId!, handler: { (success: Bool, filename: String?) -> Void in
                        if success {
                            self.progressView.hidden = true

                            OH_OAuth2.sharedInstance().getMemberInfo({ (memberId, messagePermission, usernameShared, username, files) in
                                self.fileList = files
                                dispatch_async(dispatch_get_main_queue(),{
                                    self.activityIndicator.stopAnimating()
                                    self.uploadButton.userInteractionEnabled = true
                                    let alert = UIAlertController(title: "Upload Succeeded", message: "Your healthkit data has been uploaded to OpenHumans.", preferredStyle: UIAlertControllerStyle.Alert)
                                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                                    
                                    self.updateDisplay()
                                    self.presentViewController(alert, animated: true, completion: nil)
                                })
                                }, onFailure: {
                                    self.activityIndicator.stopAnimating()
                                    self.uploadButton.userInteractionEnabled = true
                                    self.updateDisplay()
                                    
                                    
                            })
                            
                        } else {
                            self.uploadButton.userInteractionEnabled = true
                            self.activityIndicator.stopAnimating()
                            let alert = UIAlertController(title: "Upload Failed", message: "The upload failed, please try again later.", preferredStyle: UIAlertControllerStyle.Alert)
                            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                            
                            self.presentViewController(alert, animated: true, completion: nil)
                            self.updateDisplay()
                            
                            
                        }
                    })
                }
            }
        )
    }
    

    @IBOutlet weak var uploadData: UIButton!
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
