//
//  ViewRunController.swift
//
//	AdventureSFU: Make Your Path
//	Created for SFU CMPT 276, Instructor Herbert H. Tsang, P.Eng., Ph.D.
//	AdventureSFU was a project created by Group 12 of CMPT 276
//
//  Created by Group 12 on 3/2/17.
//  Copyright © 2017 . All rights reserved.
//
//	ViewRunController - A page where users can check out the trails map and plan a route.
//	Programmers: Karan Aujla, Carlos Abaffy, Eleanor Lewis, Chris Norris-Jones
//
//	Known Bugs:	-Route limit set to 25 waypoints currently, then assertion called and app crashes, need better method for either setting a limit or increasing number of waypoints without potentially introducing any stability issues
//
//              -Map sometimes will not load if info button is clicked first
//	Todo:   -Further functionality with regards to run details, user's ability to create run
//			-Further run details information upon creating run
//          -'Delete last point' function
//          -Choose speed
//			-In larger phone sizes, 'Save' and 'Clear' buttons conflict

//

import UIKit
import Mapbox
import MapboxDirections
import Firebase

class ViewRunController: UIViewController, MapViewDelegate {
    
    //View Outlets
    @IBOutlet weak var distanceField: UILabel!
    @IBOutlet weak var timeField: UILabel!
    
    //Variables
    var time: Double = 0
    var distance: Double = 0
    var ref: FIRDatabaseReference?
    let userID = FIRAuth.auth()?.currentUser?.uid
    var RunViewDelegate: RunViewControllerDelegate?
  //  var keys: [String] = []
    var wpts: [Waypoint] = []
    var userSpeed: Double?
    var userTime: Double = 0.0
    var userDistance: Double = 0.0
    
    @IBAction func dismissRunView(_ sender: AnyObject) {
        dismiss(animated: false, completion: nil)
    }
    //Functions
    //Functions implementing MapViewDelegate headers
    func getDistanceAndTime(distance: Double, time: Double) {
        self.distance = distance/1000
        distanceField.text = String(format: "Kms: %.2f", distance/1000)
        //Updates the distance stat of the planned route.
        ref?.child("Users").child(userID!).child("totalSeconds").observeSingleEvent(of: .value, with: { (snapshot) in
            //pull the user's name and display a welcome message
            let timevalue = snapshot.value as? Double
            self.userTime = timevalue!
            self.ref?.child("Users").child(self.userID!).child("KMRun").observeSingleEvent(of: .value, with: { (snapshot) in
                //pull the user's name and display a welcome message
                let distancevalue = snapshot.value as? Double
                self.userDistance = distancevalue!
                if self.userDistance != 0 && self.userTime != 0 {
                    self.userSpeed = self.userDistance/self.userTime
                    self.time = self.distance * self.userSpeed!
                } else {
                    self.time = time
                }
                print("userDistance, userTime: \(self.userDistance), \(self.userTime)")
                    let seconds = Int(time) % 60;
                    let minutes = Int(time / 60) % 60;
                    let hours = Int(time / 3600);
                self.timeField.text = String(format: "H:M:S: %d:%.2d:%.2d", hours, minutes, seconds)
                    //Updates the time stat of the planned route with the user's average speed if initialized or the Mapbox time estimate.
            })
        })
    }
    
    @IBAction func restoreRoute(_ sender: AnyObject) {
        self.RunViewDelegate?.deleteAllPoints()
        GlobalVariables.sharedManager.plannedWaypoints.removeAll()
        self.getRouteFromDB()
        //clears current route from memory, then loads stored route, if any, from Firebase
    }
    
    //Load Actions
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = FIRDatabase.database().reference()
       //set the Firebase user reference.
    }
   
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func getRouteFromDB() {
        self.ref?.child("Users").child(userID!).child("presetRoute").queryOrderedByKey().observeSingleEvent(of: .value, with: {
                        snapshot in
                for childSnap in snapshot.children{
                guard let childSnapshot = childSnap as? FIRDataSnapshot else {
                    continue
                }
                let id = childSnapshot.key
           //     self.keys.append(id)
                self.ref?.child("Users").child(self.userID!).child("presetRoute").child(id).observeSingleEvent(of: .value, with: { (snapshot) in
                        let value = snapshot.value as? NSDictionary
                        let lat = value!["lat"] as! Double
                        let long = value!["long"] as! Double
                        let location = CLLocationCoordinate2D(latitude: lat, longitude: long)
                        let wpt = Waypoint(coordinate: location, name: String(id))
                        GlobalVariables.sharedManager.plannedWaypoints.append(wpt)
                    self.RunViewDelegate?.handleRoute()
                })
                }
            })
       // one by one, get the coordinates from the preset Route, if any, load them into GlobalVariables 
        //and call the MapUI method to add them to the map
    }
  
    //Actions
    @IBAction func runToMain() {
        performSegue(withIdentifier: "runControllerToMain", sender: self)
        //Returns user to main page.
    }
    
    @IBAction func helpPopup(_ sender: Any) {
        let infoAlert = UIAlertController(title: "Route Plan Help", message: "On this page you can plan your route. Select a starting point and subsequent points by single tap to generate a route and get its distance and estimated travel time. Select CLEAR to start over. Select SAVE to keep this route available for when you next log in. Select RESTORE to load a saved route. Select Run! to start tracking your run!", preferredStyle: .alert)
        let agreeAction = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
        infoAlert.addAction(agreeAction)
        self.present(infoAlert, animated: true, completion: nil)
        //Info for the user about what to do on this page.
    }
   
    @IBAction func DeleteAllPoints(_ sender: UIButton) {
        GlobalVariables.sharedManager.plannedWaypoints.removeAll()
        self.RunViewDelegate?.deleteAllPoints()
        distanceField.text = String(format: "Kms: %.2f", 0)
        timeField.text = String("H:M:S: 0:0:0")
        //Resets time and distance stats to zero and prompts MapUI to delete the planned route.
    }
    
    @IBAction func submitRunStats(_ sender: AnyObject) {
        self.ref?.child("Users").child(self.userID!).child("presetRoute").setValue("")
        for wpt in GlobalVariables.sharedManager.plannedWaypoints {
            let key = self.ref?.child("Users").child(self.userID!).child("presetRoute").childByAutoId().key
            let waypt: NSDictionary = ["lat" : wpt.coordinate.latitude,
                                       "long" : wpt.coordinate.longitude]
            self.ref?.child("Users").child(self.userID!).child("presetRoute").updateChildValues(["/\(key)" : waypt])
        }
        self.submissionAlert()
        //Submits run plan to Firebase (as a list of coordinates).
    }
    
    func submissionAlert() {
        let alertController = UIAlertController(title: "Run is stored", message:nil, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
        alertController.addAction(defaultAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    // Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "runpageembed" {
            let childViewController = segue.destination as? MapUI
            childViewController?.delegate = self
            self.RunViewDelegate = segue.destination as? MapUI
        }
        //Define self as MapViewDelegate for embedded MapUI, and embedded MapUI as RunViewDelegate for self.
    }
    
    
}
