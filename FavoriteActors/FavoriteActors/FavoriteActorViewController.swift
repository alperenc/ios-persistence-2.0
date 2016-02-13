//
//  FavoriteActorViewController.swift
//  FavoriteActors
//
//  Created by Jason on 1/31/15.
//  Copyright (c) 2015 Udacity. All rights reserved.
//

import UIKit
import CoreData

class FavoriteActorViewController : UITableViewController, ActorPickerViewControllerDelegate {
    
    var actors = [Person]()
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.leftBarButtonItem = self.editButtonItem()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: "addActor")

        actors = fetchAllActors()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
    }
    
    // MARK: - Core Data Convenience. This will be useful for fetching. And for adding and saving objects as well.
    
    var sharedContext: NSManagedObjectContext {
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return delegate.managedObjectContext
    }

    /**
     * This is the convenience method for fetching all persistent actors.
     * Right now there are three actors pre-loaded into Core Data. Eventually
     * Core Data will only store the actors that the users chooses.
     *
     * The method creates a "Fetch Request" and then executes the request on
     * the shared context.
     */
    
    func fetchAllActors() -> [Person] {
        
        // Create the Fetch Request
        let fetchRequest = NSFetchRequest(entityName: "Person")
        
        // Execute the Fetch Request
        do {
            return try sharedContext.executeFetchRequest(fetchRequest) as! [Person]
        } catch _ {
            return [Person]()
        }
    }

    
    // Mark: - Actions
    
    func addActor() {
        let controller = self.storyboard!.instantiateViewControllerWithIdentifier("ActorPickerViewController") as! ActorPickerViewController
        
        controller.delegate = self
        
        self.presentViewController(controller, animated: true, completion: nil)
    }
    
    // MARK: - Actor Picker Delegate
    
    func actorPicker(actorPicker: ActorPickerViewController, didPickActor actor: Person?) {
        
        
        if let newActor = actor {
            
            // Check to see if we already have this actor. If so, return.
            for a in actors {
                if a.id == newActor.id {
                    return
                }
            }
            
            // Create a dictionary from the actor. Careful, the imagePath can be hil.
            
            var dictionary = [String : AnyObject]()
            dictionary[Person.Keys.ID] = newActor.id
            dictionary[Person.Keys.Name] = newActor.name
            
            if let imagePath = newActor.imagePath {
                dictionary[Person.Keys.ProfilePath] = imagePath
            }

            // Insert the actor on the main thread
            
            dispatch_async(dispatch_get_main_queue()) {
             
                // Init the Person, using the shared Context
                let actorToBeAdded = Person(dictionary: dictionary, context: self.sharedContext)
                
                do {
                    try self.sharedContext.save()
                } catch let error as NSError  {
                    print("Error saving context: \(error.localizedDescription)")
                }

                // Append the actor to the array
                self.actors.append(actorToBeAdded)
            }
        }
    }
    
    // MARK: - Table View
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actors.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let actor = actors[indexPath.row]
        let CellIdentifier = "ActorCell"
        
        let cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier) as! ActorTableViewCell
        
        cell.nameLabel!.text = actor.name
        cell.frameImageView.image = UIImage(named: "personFrame")
        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        
        if let localImage = actor.image {
            cell.actorImageView.image = localImage
        } else if actor.imagePath == nil || actor.imagePath == "" {
            cell.actorImageView.image = UIImage(named: "personNoImage")
        }
            
            // If the above cases don't work, then we should download the image
            
        else {
            
            // Set the placeholder
            cell.actorImageView.image = UIImage(named: "personPlaceholder")
            
            let size = TheMovieDB.sharedInstance().config.profileSizes[1]
            let task = TheMovieDB.sharedInstance().taskForImageWithSize(size, filePath: actor.imagePath!) { (imageData, error) -> Void in
                
                if let data = imageData {
                    dispatch_async(dispatch_get_main_queue()) {
                        let image = UIImage(data: data)
                        actor.image = image
                        cell.actorImageView.image = image
                    }
                }
            }
            
            cell.taskToCancelifCellIsReused = task
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let controller = storyboard!.instantiateViewControllerWithIdentifier("MovieListViewController") as! MovieListViewController
        
        controller.actor = actors[indexPath.row]
        
        self.navigationController!.pushViewController(controller, animated: true)
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        switch (editingStyle) {
        case .Delete:
            actors.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
        default:
            break
        }
    }
    
    // MARK: - Saving the array
    
    var actorArrayURL: NSURL {
        let filename = "favoriteActorsArray"
        let documentsDirectoryURL: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        
        return documentsDirectoryURL.URLByAppendingPathComponent(filename)
    }
}































