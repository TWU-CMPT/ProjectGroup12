//
//  ActiveRunController.swift
//  AdventureSFU
//
//  Created by ela50 on 3/14/17.
//  Copyright © 2017 Karan Aujla. All rights reserved.
//
//todo:
//zoom out map to include starting point and current location
//log waypoints to firebase
//figure out route storage with multiple points
import UIKit
import Mapbox
import MapboxDirections
import Firebase
import CoreLocation

class ActiveRunController: ViewRunController, ActiveMapViewDelegate, CLLocationManagerDelegate {
    var locationManager:CLLocationManager!
    var actualWaypointNumber: Int = 0
    var activeDelegate: ActiveRunControllerDelegate?
    var actualWaypoints: [Waypoint] = []
    let calendar = Calendar.current
    var actualTotalDistance: Double = 0
    //var ref: FIRDatabaseReference?
    // let userID = FIRAuth.auth()?.currentUser?.uid
    //    var running: Bool = true //not currently in use
    
    //@IBOutlet weak var pauseButton: UIButton!
    
    override func getTime(time: Double) -> Double? {
        return 0
    }
    
    override func getDistance(distance: Double) -> Double? {
        return 0
    }
    //    @IBAction func StopStartRun(_ sender: UIButton) {
    //        if (running) {
    //            self.locationManager.stopUpdatingLocation()
    //        pauseButton.setTitle("", for: [])
    //        pauseButton.setTitle("Resume run recording", for: [])
    //         running = false
    //
    //        }
    //        else {
    //            running = true
    //            self.locationManager.startUpdatingLocation()
    //            pauseButton.setTitle("Pause run recording", for: [])
    //        }
    //      //pause/resume user-route tracking.
    //    }
    //   //not currently in use.
    
    override func viewDidLoad() {
        super.viewDidLoad()
        GlobalVariables.sharedManager.startTime = Date()
        
        //      pauseButton.setTitle("Pause run recording", for: []) //not currently in use.
        self.locationManager = CLLocationManager()
        self.locationManager.requestAlwaysAuthorization()
        if (CLLocationManager.locationServicesEnabled()) {
            self.locationManager.delegate = self
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest //is this necessary?
            self.locationManager.distanceFilter = kCLLocationAccuracyBest
            self.locationManager.startUpdatingLocation()
        }
        // Initiate user-route updating and set start time.
        // Do any additional setup after loading the view.
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        let location = locations.last! as CLLocation
        let wpt: Waypoint = Waypoint(coordinate: location.coordinate, name: "\(actualWaypointNumber)")
        actualWaypoints.append(wpt)
        actualWaypointNumber = actualWaypointNumber + 1
        GlobalVariables.sharedManager.actualWaypoints.append(wpt)
        if actualWaypointNumber > 2 {
            self.activeDelegate?.appendToDrawnRoute()
        }
        
        if actualWaypointNumber > 1 {
            let prevLocation = CLLocation(latitude: actualWaypoints[actualWaypoints.count-2].coordinate.latitude, longitude: actualWaypoints[actualWaypoints.count-2].coordinate.longitude)
            //   print("searchable prev and current location: \(prevLocation.coordinate), \(location.coordinate)")
            let tempTotalDistance: Double = location.distance(from: prevLocation)
            self.actualTotalDistance = self.actualTotalDistance + tempTotalDistance
            //     print("searchable temp/total metres: \(tempTotalDistance), \(self.actualTotalDistance)")
        }
        
        //     print("searchable long and lat\(location.coordinate.longitude),\(location.coordinate.latitude)")
        // Tracks user's position. Sends data to GlobalVariables.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    //    override func getTime(time: Double) -> Double? {
    //        self.time = time
    //        return time
    //    }
    //
    //    override func getDistance(distance: Double) -> Double? {
    //        self.distance = distance/1000
    //        return distance
    //    }
    
    @IBAction func stopRun() {
        self.locationManager.stopUpdatingLocation()
        performSegue(withIdentifier: "stopRun", sender: self)
    }
    @IBAction func activeRunHelp(_ sender: Any) {
  
            let infoAlert = UIAlertController(title: "Run Tracking Help", message: "On this page you can see a record of your route on this trip. Select End Run! to stop recording and go back to the Route Planning page. Your total distance and time will be updated to include the distance and time from this trip.", preferredStyle: .alert)
            let agreeAction = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
            infoAlert.addAction(agreeAction)
            self.present(infoAlert, animated: true, completion: nil)
        
        
    }
    // Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "activerunembed" {
            self.activeDelegate = segue.destination as? ActiveMapUI
            let childViewController = segue.destination as? ActiveMapUI
            childViewController?.delegate = self
            childViewController?.preselectedRoute = self.presetRoute
            childViewController?.waypoints = self.waypoints
            
            //Define self as delegate for embedded ActiveMapUI.
            //Define embedded ActiveMapUI as delegate for self.
            
        }
        if segue.identifier == "stopRun" {
            print("searchable made it to stopRUN prepare")
            GlobalVariables.sharedManager.hasRunData = true
            GlobalVariables.sharedManager.endTime = Date()
            GlobalVariables.sharedManager.elapsedTimeThisRun = GlobalVariables.sharedManager.endTime!.timeIntervalSince(GlobalVariables.sharedManager.startTime!)
            GlobalVariables.sharedManager.distanceThisRun = self.actualTotalDistance
            super.ref?.child("Users").child(super.userID!).child("totalMins").observeSingleEvent(of: .value, with: { (snapshot) in
                let tempTotalTime = snapshot.value as? TimeInterval
                if var totalTime = tempTotalTime {
                    totalTime = tempTotalTime! + (GlobalVariables.sharedManager.elapsedTimeThisRun! as Double)/60
                    super.ref?.child("Users").child(super.userID!).child("totalMins").setValue(totalTime as Double!)
                    print("searchable totalTime: \(totalTime)")
                }
            })
            
            //test code
            print("searchable time \(GlobalVariables.sharedManager.elapsedTimeThisRun)")
            
            var tempTotalKm: Double?
            super.ref?.child("Users").child(super.userID!).child("KMRun").observeSingleEvent(of: .value, with: { (snapshot) in
                tempTotalKm = snapshot.value as? Double
                print("searchable firebase total km: \(tempTotalKm)")
                if var totalKm = tempTotalKm {
                    totalKm = self.actualTotalDistance/1000 + tempTotalKm!
                    super.ref?.child("Users").child(super.userID!).child("KMRun").setValue(totalKm)
                }
            })
            
            let childViewController = segue.destination as? ViewRunController
            childViewController?.route = self.route
            childViewController?.presetRoute=self.presetRoute
            
            //Store run data in GlobalVariables and Firebase.
        }
    }
}
