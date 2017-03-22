//
//  MapUI.swift
//
//	AdventureSFU: Make Your Path
//	Created for SFU CMPT 276, Instructor Herbert H. Tsang, P.Eng., Ph.D.
//	AdventureSFU was a project created by Group 12 of CMPT 276
//
//  Created by Group 12 on 3/2/17.
//  Copyright © 2017 . All rights reserved.
//
//	MapUI - The signup screen that alows users to create their account
//	Programmers: Karan Aujla, Carlos Abaffy, Eleanor Lewis, Chris Norris-Jones
//
//	Known Bugs:	-Stop warning flags from unused variables from displaying, when variables are in fact being used
//	Todo:	implement double-tap removes points from planned route
//implement scrap it and start over
//implement Active map changes to gesture recognition - fixed route
//implement remove last waypoint
//remove unneeded variables, format, comment, clean up
//use more attractive map
//implement 25 points max
import UIKit
import Mapbox
import MapboxDirections

class MapUI: UIViewController, RunViewControllerDelegate {
    
    //View Outlets
    @IBOutlet var MapUI: MGLMapView!
    
    //Variables
    var delegate: MapViewDelegate?
    var coordinates: [CLLocationCoordinate2D] = []
    var waypoints: [Waypoint] = []
    var directions = Directions.shared;
    var preselectedRoute: Route?
    var names: Int = 0
    var start = MGLPointAnnotation()
    var preselectedWaypoints: [Waypoint] = []
    
    
    //Load Actions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        MapUI = MGLMapView(frame: view.bounds)
        MapUI.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(MapUI)
        MapUI.setCenter(CLLocationCoordinate2D(latitude: 49.273382, longitude: -122.908837),
                        zoomLevel: 13, animated: false)
        if (GlobalVariables.sharedManager.plannedWaypoints.count > 0) {
            handleRoute()
        }
        
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        // doubleTap.require(toFail: tripleTap)
        
        MapUI.addGestureRecognizer(doubleTap)
        
        // define singleTap relative to doubleTap
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap))
        singleTap.require(toFail: doubleTap)
        MapUI.addGestureRecognizer(singleTap)
        //Load map centred at specified coordinates. Add gesture recognizers doubleTap and singleTap.
        
        
    }
    
    //Functions
    
    func deleteAllPoints() {
       
        if (GlobalVariables.sharedManager.plannedWaypoints.count > 0) {
            GlobalVariables.sharedManager.plannedWaypoints.removeAll()
            
            
        }
        if (MapUI.annotations?.count != nil) {
            MapUI.removeAnnotations(MapUI.annotations!)
            // remove drawn route so new route can be drawn
        }
    }
    
    //    func deleteLastPoint() {
    //print("searchable mapui made it to deleteLastPoint")
    //        let waypointsCount = GlobalVariables.sharedManager.plannedWaypoints.count
    //        if waypointsCount > 0 {
    //        GlobalVariables.sharedManager.plannedWaypoints.remove(at: waypointsCount - 1)
    //        }
    //        if (self.MapUI.annotations != nil) {
    //            let annotationsCount = self.MapUI.annotations?.count
    //                if (annotationsCount! > 0) {
    //                    self.MapUI.removeAnnotation((MapUI.annotations?[(MapUI.annotations?.count)! - 1])!)
    //                }
    //        }
    //    }
    
    func handleSingleTap(tap: UITapGestureRecognizer) {
        let location: CLLocationCoordinate2D = MapUI.convert(tap.location(in: MapUI), toCoordinateFrom: MapUI)
       
        let wpt: Waypoint = Waypoint(coordinate: location, name: "\(names)")
        GlobalVariables.sharedManager.plannedWaypoints.append(wpt)
        //update current list of coordinates
        self.names = self.names + 1
        
        // if at least 2 points are specified, calculate and draw route. update local and delegate stats.
        
        handleRoute()
        
        
    }
    
    
    func handleDoubleTap(tap: UITapGestureRecognizer) {
        //        print("searchable doubletap")
        //        if (self.names > 0) {
        //            waypoints.remove(at: (self.names-1))
        //            self.names = self.names-1
        //
        //        self.delegate?.deleteWaypoint()
        //        }
        //        // remove existing polyline from the map, (re)add polyline with coordinates
        //
        //            MapUI.removeAnnotations(MapUI.annotations!)
        //        handleRoute()
    }
    
    
    func handleRoute() {
        
        
        
        if GlobalVariables.sharedManager.plannedWaypoints.count > 0 { // Declare the marker 'start' and set its coordinates, title, and subtitle.
            
            
            start.coordinate = GlobalVariables.sharedManager.plannedWaypoints[0].coordinate
            start.title="Start"
            
            // Add marker `start` to the map.
            MapUI.addAnnotation(start)
            
            
            if GlobalVariables.sharedManager.plannedWaypoints.count > 1 {
                
                
                let options = RouteOptions(waypoints: GlobalVariables.sharedManager.plannedWaypoints, profileIdentifier: MBDirectionsProfileIdentifierWalking)
                //define directions info - coordinates and travel speed
                
                _ = directions.calculate(options) { (waypoints, routes, error) in
                    guard error == nil else {
                        
                        return
                    }
                    
                    if let route = routes?.first {
                        self.drawRoute(route: route)
                    }
                    
                }
            }
        }
    }
    func drawRoute(route: Route) {
       
        //gets the time and distance for the drawn route. 
        //don't listen to xcode these are necessary and used
        
        self.delegate?.getRoute(chosenRoute: route)
        self.delegate?.getTime(time: route.expectedTravelTime)
        self.delegate?.getDistance(distance: route.distance)
        //submit route, distance and time info to delegate
        //        start.coordinate = GlobalVariables.sharedManager.plannedWaypoints[0].coordinate
        //        start.title="Start"
        //        // Add marker `start` to the map.
        //        MapUI.addAnnotation(start)
        var routeCoordinates = route.coordinates!
        let routeLine = MGLPolyline(coordinates: &routeCoordinates, count: route.coordinateCount)
        self.MapUI.addAnnotation(routeLine)
        
        //redraw route
				}
    
    //Updates route with coordinates selected by singleTap.
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
}


