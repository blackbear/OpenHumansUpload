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

class ExportMenu: UIViewController {
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var uploadButton: UIButton!
    
    @IBOutlet weak var incrementalButton: UIButton!
    @IBOutlet weak var editUploadButton: UIButton!
    @IBOutlet weak var incrementalLabel: UILabel!
    
    var alert : UIAlertController!
    var fileList : JSONArray = JSONArray()
    let healthStore     = HKHealthStore()
    
    func updateUI() {
        let defs = NSUserDefaults.standardUserDefaults()
        let lastDate = defs.objectForKey("lastSaveDate") as! NSDate?
        if (lastDate == nil) {
            incrementalButton.hidden = true
            incrementalLabel.hidden = true
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.uploadButton.layer.cornerRadius=5
        self.incrementalButton.layer.cornerRadius=5
        self.updateUI()
    }

    
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
        if segue.identifier == "uploadToMainMenu" {
            let vc = segue.destinationViewController as! MainMenu
            vc.fileList = self.fileList
        }
    }
    
        @IBOutlet weak var progressView: UIProgressView!
    
    @IBAction func uploadIncremental(sender: AnyObject) {
        self.view.userInteractionEnabled = false
        activityIndicator.startAnimating()
        let defs = NSUserDefaults.standardUserDefaults()
        let lastDate = defs.objectForKey("lastSaveDate") as! NSDate?
        let configuration   = HealthDataFullExportConfiguration(profileName: "Profilname", exportType: HealthDataToExportType.ALL, startDate: lastDate, endDate: NSDate())
        let target = JsonSingleDocInMemExportTarget()
        self.progressView.progress = 0
        self.progressView.hidden = false
        // and pass it to the HealthKitDataExporter
        let exporter        = HealthKitDataExporter(healthStore: healthStore)
        exporter.export(
            
            exportTargets: [target],
            
            exportConfiguration: configuration,
            
            onProgress: {
                (message: String, progressInPercent: NSNumber?) -> Void in
                // output progress messages
                dispatch_async(dispatch_get_main_queue(), {
                    self.progressView.progress = (progressInPercent?.floatValue)!
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
                    var fname = "healthkit-export_" + dayTimePeriodFormatter.stringFromDate(lastDate!)
                    fname = fname + "_" + dayTimePeriodFormatter.stringFromDate(NSDate()) + "_"
                    fname = fname + String(NSDate().timeIntervalSince1970) + ".json"
                    print(fname + "\n")
                    
                    OH_OAuth2.sharedInstance().uploadFile(fname, data: target.getJsonString(), memberId: OH_OAuth2.sharedInstance().memberId!, handler: { (success: Bool, filename: String?) -> Void in
                        if success {
                            dispatch_async(dispatch_get_main_queue(), {
                                self.progressView.hidden = true
                            })
                            
                            OH_OAuth2.sharedInstance().getMemberInfo({ (memberId, messagePermission, usernameShared, username, files) in
                                self.fileList = files
                                dispatch_async(dispatch_get_main_queue(),{
                                    defs.setObject(NSDate(), forKey: "lastSaveDate")

                                        self.updateUI()
                                        self.activityIndicator.stopAnimating()
                                    self.view.userInteractionEnabled = true
                                    self.alert = UIAlertController(title: "Upload Succeeded", message: "Your healthkit data has been uploaded to OpenHumans.", preferredStyle: UIAlertControllerStyle.Alert)
                                    self.alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                                    
                                    self.presentViewController(self.alert, animated: true, completion: nil)
                                })
                                }, onFailure: {
                                    self.activityIndicator.stopAnimating()
                                    self.view.userInteractionEnabled = true
                                    
                                    
                            })
                            
                        } else {
                            self.view.userInteractionEnabled = true
                            self.activityIndicator.stopAnimating()
                            self.alert = UIAlertController(title: "Upload Failed", message: "The upload failed, please try again later.", preferredStyle: UIAlertControllerStyle.Alert)
                            self.alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                            
                            self.presentViewController(self.alert, animated: true, completion: nil)
                            
                            
                        }
                    })
                }
            }
        )
    }
    
    func outputMonth(now : NSDate, currentDate : NSDate) -> Void {
        if currentDate.compare(now) != NSComparisonResult.OrderedDescending {
            let cal = NSCalendar.currentCalendar()
            let nextMonth = cal.dateByAddingUnit(NSCalendarUnit.Month, value: 1, toDate: currentDate, options: NSCalendarOptions(rawValue: 0))
            let endOfMonth = cal.dateByAddingUnit(NSCalendarUnit.Second, value: -1, toDate: nextMonth!, options: NSCalendarOptions(rawValue: 0))
            let configuration   = HealthDataFullExportConfiguration(profileName: "Profilname", exportType: HealthDataToExportType.ALL, startDate: currentDate, endDate: endOfMonth)
            let target = JsonSingleDocInMemExportTarget()
            // create your instance of HKHeakthStore
            // and pass it to the HealthKitDataExporter
            let exporter        = HealthKitDataExporter(healthStore: healthStore)
            exporter.export(
                
                exportTargets: [target],
                
                exportConfiguration: configuration,
                
                onProgress: {
                    (message: String, progressInPercent: NSNumber?) -> Void in
                    // output progress messages
                    dispatch_async(dispatch_get_main_queue(), {
                        //                        print(message)
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
                        var fname = "healthkit-export_" + dayTimePeriodFormatter.stringFromDate(currentDate)
                        fname = fname + "_" + dayTimePeriodFormatter.stringFromDate(endOfMonth!) + "_"
                        fname = fname + String(now.timeIntervalSince1970) + ".json"
                        if (target.hasSamples()) {
                            print(fname + "\n")
                            print(target.getJsonString())
                            OH_OAuth2.sharedInstance().uploadFile(fname, data: target.getJsonString(), memberId: OH_OAuth2.sharedInstance().memberId!, handler: { (success: Bool, filename: String?) -> Void in
                                if success {
                                    self.outputMonth(now, currentDate: nextMonth!)
                                    let defs = NSUserDefaults.standardUserDefaults()
                                    if endOfMonth?.compare(now) == .OrderedAscending {
                                        defs.setObject(endOfMonth, forKey: "lastSaveDate")
                                    } else {
                                        defs.setObject(now, forKey: "lastSaveDate")
                                    }
                                } else {
                                    self.view.userInteractionEnabled = true
                                    self.activityIndicator.stopAnimating()
                                    self.alert = UIAlertController(title: "Upload Failed", message: "The upload failed, please try again later.", preferredStyle: UIAlertControllerStyle.Alert)
                                    self.alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                                    
                                    self.presentViewController(self.alert, animated: true, completion: nil)
                                    return
                                }
                                
                                
                            })
                            
                        } else {
                            print("No data for " + dayTimePeriodFormatter.stringFromDate(currentDate))
                            self.outputMonth(now, currentDate: nextMonth!)
                            let defs = NSUserDefaults.standardUserDefaults()
                            if endOfMonth?.compare(now) == .OrderedAscending {
                                defs.setObject(endOfMonth, forKey: "lastSaveDate")
                            } else {
                                defs.setObject(now, forKey: "lastSaveDate")
                            }
                        }

                    }
            })
        } else {
            
            OH_OAuth2.sharedInstance().getMemberInfo({ (memberId, messagePermission, usernameShared, username, files) in
                self.fileList = files
                dispatch_async(dispatch_get_main_queue(),{
                    self.activityIndicator.stopAnimating()
                    self.view.userInteractionEnabled = true
                    self.alert = UIAlertController(title: "Upload Succeeded", message: "Your healthkit data has been uploaded to OpenHumans.", preferredStyle: UIAlertControllerStyle.Alert)
                    self.alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                    
                    self.presentViewController(self.alert, animated: true, completion: nil)
                })
                }, onFailure: {
                    self.activityIndicator.stopAnimating()
                    self.view.userInteractionEnabled = true
                    
                    
            })
            
            
        }
    }
    
    @IBOutlet weak var datePickView: UIView!
    @IBOutlet weak var startButton: UIButton!
    @IBAction func uploadData(sender: AnyObject) {
        view.userInteractionEnabled = false
        activityIndicator.startAnimating()
        let defs = NSUserDefaults.standardUserDefaults()
        let now = NSDate()
        defs.setObject(now, forKey: "lastSaveDate")
        outputMonth(now, currentDate: NSDate(timeIntervalSince1970: 1104537600))
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
