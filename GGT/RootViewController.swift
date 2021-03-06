//
//  RootViewController.swift
//  GGT
//
//  Created by Matt Kostelecky on 4/26/15.
//  Copyright (c) 2015 Matt Kostelecky. All rights reserved.
//

import Foundation
import UIKit

class RootViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
  
  @IBOutlet weak var tableGrants: UITableView!
  var grants: NSMutableArray = NSMutableArray()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    tableGrants.delegate = self
    tableGrants.dataSource = self
    download()
  }
  
  override func viewDidAppear(animated: Bool) {
    let save: NSData? = NSUserDefaults.standardUserDefaults().dataForKey("grants")
  
    if((save) != nil) {
      self.grants = NSKeyedUnarchiver.unarchiveObjectWithData(save!) as! NSMutableArray
      println()
    }
    
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    // #warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 1
  }
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    // #warning Incomplete method implementation.
    // Return the number of rows in the section.
    
    return self.grants.count
  }
  
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    var cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! GrantCell
    
    // Configure the cell...
    let grant: GrantObject = self.grants.objectAtIndex(indexPath.row) as! GrantObject
    cell.grantNameLabel.text = (grant.getMetadata() as NSDictionary).objectForKey("title") as? String
    cell.endDateLabel.text = self.formatEndDate(grant) as String
    cell.remainingMoneyLabel.text = self.formatBalance(grant) as String
    return cell
  }
  
  // MARK: - TableView data source
  
   func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    tableView.deselectRowAtIndexPath(indexPath, animated: true)
   
    
    //remove the correct post from the array here, set the controller's post propert
    
  }
  
  func download() {
  
    let key = "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08"
    let urlString: NSString = NSString(format: "http://pages.cs.wisc.edu/~mihnea/ggt/sheets/ggt_handler.php?type=download&fname=%@&key=%@", "samplefile.enc", key)
    
    let url: NSURL = NSURL(string: urlString.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!)!
    
    let session: NSURLSession = NSURLSession.sharedSession()
    session.dataTaskWithURL(url, completionHandler: { (data:NSData!, response:NSURLResponse!, error:NSError!) -> Void in
      
      let json: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.allZeros, error: NSErrorPointer()) as! NSDictionary
      println(json)
      
      let grantObject: GrantObject = GrantObject(CSVArray: json.objectForKey("data") as! [AnyObject])
      self.grants.addObject(grantObject)
    
      let save: NSData = NSKeyedArchiver.archivedDataWithRootObject(self.grants)
      NSUserDefaults.standardUserDefaults().setObject(save, forKey: "directories")
      NSUserDefaults.standardUserDefaults().synchronize()
      
      self.tableGrants.reloadData()
      
    }).resume()
    
  }
  
  func formatEndDate(grant: GrantObject) -> NSString {
    let formatter: NSDateFormatter = NSDateFormatter()
    formatter.dateFormat = "mm/dd/YYYY"
    
    let metaData: NSDictionary = grant.getMetadata()

    let endDate = formatter.dateFromString(metaData.objectForKey("endDate") as! String)
    formatter.dateFormat = "MMM dd, yyyy"
    
    return formatter.stringFromDate(endDate!)
  }
 
  func formatCurrency(amount: NSString) -> NSDecimalNumber {
    var ret = amount.stringByReplacingOccurrencesOfString("\"", withString: "").stringByReplacingOccurrencesOfString(",", withString: "")
    let retArray: NSArray = ret.componentsSeparatedByString(".")
    ret = retArray.objectAtIndex(0) as! String
    
    return NSDecimalNumber(string: ret)
  }
  
  func formatBalance(grant: GrantObject) -> NSString{
    let budget: NSDecimalNumber =  self.formatCurrency((grant.getBudgetRow() as NSDictionary).objectForKey("Amount") as! NSString)
    let balance: NSDecimalNumber =  self.formatCurrency((grant.getBalanceRow() as NSDictionary).objectForKey("Amount") as! NSString)
    
    let numberFormatter: NSNumberFormatter = NSNumberFormatter()
    numberFormatter.numberStyle = NSNumberFormatterStyle.CurrencyStyle
    
    var balanceString: NSString = numberFormatter.stringFromNumber(balance)!
    var budgetString: NSString = numberFormatter.stringFromNumber(budget)!
    
    balanceString = balanceString.stringByReplacingOccurrencesOfString(".00", withString: "")
    budgetString = budgetString.stringByReplacingOccurrencesOfString(".00", withString: "")
    
    return NSString(format: "%@ of %@ remaining", balanceString, budgetString)
    
  }
  
}