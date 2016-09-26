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
    @IBOutlet weak var progressView1: UIProgressView!
    
    var alert : UIAlertController!
    var fileList : JSONArray = JSONArray()
    var progressIncrement : Float!
    let healthStore     = HKHealthStore()
    
    func updateUI() {
        self.progressView.hidden = true
        self.progressView1.hidden = true

        
    }
      
    override func viewDidLoad() {
        super.viewDidLoad()
        self.uploadButton.layer.cornerRadius=5
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
    
    func generateMonthData(now : NSDate, currentDate : NSDate) -> Void {
        let cal = NSCalendar.currentCalendar()
        var nextMonth = cal.dateByAddingUnit(NSCalendarUnit.Month, value: 1, toDate: currentDate, options: NSCalendarOptions(rawValue: 0))
        nextMonth = cal.dateBySettingUnit(NSCalendarUnit.Day, value: 1, ofDate: nextMonth!, options: NSCalendarOptions(rawValue: 0))
        var endOfMonth = cal.dateByAddingUnit(NSCalendarUnit.Second, value: -1, toDate: nextMonth!, options: NSCalendarOptions(rawValue: 0))
        if (now.compare(endOfMonth!) == .OrderedAscending) {
            endOfMonth = now
        }
        let configuration   = HealthDataFullExportConfiguration(profileName: "Profilname", exportType: HealthDataToExportType.ALL, startDate: currentDate, endDate: endOfMonth!)
        let target = JsonSingleDocInMemExportTarget()
        // create your instance of HKHeakthStore
        // and pass it to the HealthKitDataExporter
        let exporter        = HealthKitDataExporter(healthStore: healthStore)
        exporter.export(
            
            exportTargets: [target],
            
            exportConfiguration: configuration,
            
            onProgress: {
                (message: String, progressInPercent: NSNumber?) -> Void in
                dispatch_async(dispatch_get_main_queue(), {
                    self.progressView.progress = (progressInPercent?.floatValue)!
                })
            },
            
            onCompletion: {
                (error: ErrorType?)-> Void in
                // output the result - if error is nil. everything went well
                if error != nil {
                    var continuing = false
                    self.alert = UIAlertController(title: "Export Failed", message: error.debugDescription, preferredStyle: UIAlertControllerStyle.Alert)
                    if error.debugDescription.containsString("Protected health data") {
                        self.alert = UIAlertController(title: "Export Paused", message: "The export will pause if the phone is locked during the operation.", preferredStyle: UIAlertControllerStyle.Alert)
                        continuing = true
                        
                    }
                    self.alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler:  { (act) -> Void in
                        if continuing {
                            self.view.userInteractionEnabled = false
                            self.activityIndicator.startAnimating()
                        }
                        }))
                    
                    self.presentViewController(self.alert, animated: true, completion: nil)
                    return
                } else {
                    let dayTimePeriodFormatter = NSDateFormatter()
                    dayTimePeriodFormatter.dateFormat = "yyyy-MM-dd"
                    var fname = "healthkit-export_" + dayTimePeriodFormatter.stringFromDate(currentDate)
                    fname = fname + "_" + dayTimePeriodFormatter.stringFromDate(endOfMonth!) + "_"
                    fname = fname + String(now.timeIntervalSince1970) + ".json"
                    if (target.hasSamples()) {
                        OH_OAuth2.sharedInstance().uploadFile(fname, data: target.getJsonString(), memberId: OH_OAuth2.sharedInstance().memberId!, handler: { (success: Bool, filename: String?) -> Void in
                            if success {
                                dispatch_async(dispatch_get_main_queue(), {
                                    self.progressView1.progress += self.progressIncrement
                                });
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
                        dispatch_async(dispatch_get_main_queue(), {
                            self.progressView1.progress += self.progressIncrement
                        });
                        self.outputMonth(now, currentDate: nextMonth!)
                        let defs = NSUserDefaults.standardUserDefaults()
                        defs.setObject(endOfMonth, forKey: "lastSaveDate")
                    }
                    
                }
        })
        
    }
    
    func outputMonth(now : NSDate, currentDate : NSDate) -> Void {
        if currentDate.compare(now) != NSComparisonResult.OrderedDescending {
            self.generateMonthData(now, currentDate: currentDate)
        } else {
            
            OH_OAuth2.sharedInstance().getMemberInfo({ (memberId, messagePermission, usernameShared, username, files) in
                self.fileList = files
                dispatch_async(dispatch_get_main_queue(),{
                    self.activityIndicator.stopAnimating()
                    self.view.userInteractionEnabled = true
                    self.alert = UIAlertController(title: "Upload Succeeded", message: "Your healthkit data has been uploaded to OpenHumans.", preferredStyle: UIAlertControllerStyle.Alert)
                    self.alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                    self.presentViewController(self.alert, animated: true, completion: nil)
                    self.updateUI()
                })
                }, onFailure: {
                    self.activityIndicator.stopAnimating()
                    self.view.userInteractionEnabled = true
                    self.updateUI()
                    
            })
            
            
        }
    }
    
    @IBOutlet weak var datePickView: UIView!
    @IBOutlet weak var startButton: UIButton!
    @IBAction func uploadData(sender: AnyObject) {
        let defs = NSUserDefaults.standardUserDefaults()
        var lastDate = defs.objectForKey("lastSaveDate")
        if lastDate == nil {
            lastDate = NSDate(timeIntervalSince1970: 1104537600);
        }
        view.userInteractionEnabled = false
        self.progressView1.progress = 0.0
        self.progressView.progress = 0.0
        self.progressView.hidden = false
        self.progressView1.hidden = false
        activityIndicator.startAnimating()
        let now = NSDate()
        let cal = NSCalendar.currentCalendar()
        let nmonths = cal.components(.Month, fromDate: lastDate as! NSDate, toDate: now, options: NSCalendarOptions.MatchFirst).month
        if (nmonths == 0) {
            progressIncrement = 1.0
        } else {
            progressIncrement = 1.0 / Float(nmonths)
        }
        outputMonth(now, currentDate: lastDate as! NSDate)
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
