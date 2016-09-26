//
//  DataFileView.swift
//  OpenHumansUpload
//
//  Created by James Turner on 7/1/16.
//  Copyright © 2016 Open Humans. All rights reserved.
//

import UIKit

class DataFileCell : UITableViewCell {
    
    var fileName : UILabel?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initMe()
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initMe()
    }
    
    func initMe() {
        fileName = UILabel(frame: self.frame.insetBy(dx: 10.0, dy: 0.0))
        fileName?.adjustsFontSizeToFitWidth = true
        fileName?.minimumScaleFactor = 0.1
        fileName?.textColor = UIColor.whiteColor()
        self.addSubview(fileName!)
    }
}

class DataFileView: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    var dataFiles : JSONArray = JSONArray()
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerClass(DataFileCell.self, forCellReuseIdentifier: "DataFileCell")
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
       self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return dataFiles.count
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "dataFileToMain" {
            (segue.destinationViewController as! MainMenu).fileList = dataFiles
        }
    }

    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("DataFileCell", forIndexPath: indexPath) as! DataFileCell
        let json = dataFiles[indexPath.row]
        cell.backgroundColor = tableView.backgroundColor
        cell.fileName!.text = (json["basename"] as! String)
        print(json["basename"])
        return cell
    }
    

    // Override to support conditional editing of the table view.
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    // Override to support editing the table view.
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            activityView.startAnimating()
            self.view.userInteractionEnabled = false
            let json = dataFiles[indexPath.row]
            OH_OAuth2.sharedInstance().deleteFile(json["id"] as! NSNumber, handler: {(success: Bool) in
                if (success) {
                    OH_OAuth2.sharedInstance().getMemberInfo({ (memberId, messagePermission, usernameShared, username, files) in
                        dispatch_async(dispatch_get_main_queue(), {
                            self.dataFiles.removeAtIndex(indexPath.row)
                            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                            self.dataFiles = files
                            self.activityView.stopAnimating()
                            self.view.userInteractionEnabled = true

                        })
                        }, onFailure: {
                            dispatch_async(dispatch_get_main_queue(), {
                                self.dataFiles.removeAtIndex(indexPath.row)
                                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                                self.activityView.stopAnimating()
                                self.view.userInteractionEnabled = true
                            })
                    })
                } else {
                    dispatch_async(dispatch_get_main_queue(), {
                        let alert = UIAlertController(title: "Delete Failed", message: "Unable to delete file, try again later.", preferredStyle: UIAlertControllerStyle.Alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                        
                        self.presentViewController(alert, animated: true, completion: nil)
                        self.activityView.stopAnimating()
                        self.view.userInteractionEnabled = true
                        
                        
                    })
                }
            });
            
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
