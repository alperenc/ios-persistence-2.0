// MasterViewController.swift
//
//  MasterViewController.swift
//  FetchResultsControllerMasterDetail
//
//  Created by Jason on 3/24/15.
//  Copyright (c) 2015 Udacity. All rights reserved.
//

import UIKit
import CoreData

/**
* This MasterViewController uses a NSFetchedResults controller to store Event objects. The fetched results controller
* replaces the "objects" array that has been used in past versions.
*
* It is only using the fetched results controller in the first of its roles: storage for results of a fetch
*
* It is not yet using the fetched results controller in second of its roles: to actively notify this view controller 
* of changes to the data
*/

class MasterViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    // Notice that an array of events is conspiciously missing.
    
    // The viewDidLoad method has two jobs in this view controller:
    // 1. Set the left and right navigation buttons. This is the same as last time we used MasterDetail
    // 2. Start up the fetchedResultsController. This is new.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the buttons
        self.navigationItem.leftBarButtonItem = self.editButtonItem()
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
        self.navigationItem.rightBarButtonItem = addButton
        
        // Perform the fetch. This gets the machine rolling
        // We check for an error, but we don't expect one.
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print(error)
        }
    }
    
    // MARK: - Insert new object
    
    // Create a new event, save the context.
    // This may be the most interesting method in the code. Notice the array is conspicuously missing.
    
    func insertNewObject(sender: AnyObject) {
        let event = Event(context: sharedContext)
        
        event.timeStamp = NSDate()
        
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    // Our typical lazy context var, for convenient access to the shared Managed Object Context
    
    lazy var sharedContext: NSManagedObjectContext = {
            CoreDataStackManager.sharedInstance().managedObjectContext
        }()
    
    // MARK: - Fetched Results Controller
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
            // Create the fetch request
            let fetchRequest = NSFetchRequest(entityName: "Event")
            
            // Add a sort descriptor. This enforces a sort order on the results that are generated
            // In this case we want the events sored by their timeStamps.
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timeStamp", ascending: false)]
            
            // Create the Fetched Results Controller
            let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
            fetchedResultsController.delegate = self
            
            // Return the fetched results controller. It will be the value of the lazy variable
            return fetchedResultsController
        } ()
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        default:
            return
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        // We don't need this since we are not using sections
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }
    
    
    // MARK: - Table View
    
    // These are fairly different that table view data source methods we have written before.
    // Notice how heavily they lean on the Fetched Results Controller.
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section] as NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        // *** This is, perhaps, the most novel and interesting line in the file right now. ***
        //
        // Notice that the fetchedResultsController is storing our Event objects. 
        // Here we get back an event by passing in an indexPath. The "objectAtIndexPath"
        // is designed for our convenience in this metho, cellForRowAtIndexPath
        let event = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Event
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell
        
        cell.textLabel!.text = event.timeStamp.description
        
        return cell
    }
    
    // This is the table view delegate method that is invoked when we delete a row from the table. 
    // Notice how the implementation works: 
    //  - We get the event for the index path of the row
    //  - We delete this object using the sharedContext. This is new. We haven't called this out in a commnent before
    //  - Finaly we save the contex.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if editingStyle == .Delete {
            let event = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Event
            sharedContext.deleteObject(event)
            
            CoreDataStackManager.sharedInstance().saveContext()
        }
    }
    
    // MARK: - Segues
    
    // This is a fairly typical for a Master Detail type app. But is makes an interesting use of the
    // Fetched Results Controller. Check it out.
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "showDetail" {
            
            if let indexPath = self.tableView.indexPathForSelectedRow {
                
                // Right here. We use the objectAtIndexPath again to get an Event.
                let object = fetchedResultsController.objectAtIndexPath(indexPath)
                (segue.destinationViewController as! DetailViewController).detailItem = object
            }
        }
    }
}