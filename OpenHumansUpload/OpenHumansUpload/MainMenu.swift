//
//  MainMenu.swift
//  OpenHumansUpload
//
//  Created by James Turner on 6/18/16.
//  Copyright © 2016 Open Humans. All rights reserved.
//

import UIKit
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
