//
//  LeaderBoardViewController.swift
//  AdventureSFU
//
//  Created by Karan Aujla on 3/30/17.
//  Copyright © 2017 Karan Aujla. All rights reserved.
//

import UIKit
import Firebase

class LeaderBoardViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    //Variables 
    
    var ref: FIRDatabaseReference?
    var team = "No Team"
    var  userCount = 0
    var userKeys = [String]()
    var kmValues = [Double]()
    var timeValues = [Double]()
    var usersPopulated = false
    var sortByDistance = true
    //create a struct to contain the users
    struct userStats {
        var kmRun: Double
        var timeRun: Double
        var username: String
        var userID: String
        
        
    }
    struct  userLeaderboard {
        var userArray = [userStats]()
        
        mutating func sortByTime(){
            if userArray.count <= 1{
                return
            }
            for index in 0...userArray.count - 2 {
                for innerIndex in index + 1...userArray.count - 1{
                    if userArray[innerIndex].timeRun   > userArray[index].timeRun {
                        let tempUserStat = userArray[innerIndex]
                        userArray[innerIndex] = userArray[index]
                        userArray[index] = tempUserStat
                    }
                }
            }

            
        }
        mutating func sortbyDistance(){
            if userArray.count <= 1{
                return
            }
            for index in 0...userArray.count - 2 {
                for innerIndex in index + 1...userArray.count - 1{
                    if userArray[innerIndex].kmRun   > userArray[index].kmRun {
                        let tempUserStat = userArray[innerIndex]
                        userArray[innerIndex] = userArray[index]
                        userArray[index] = tempUserStat
                    }
                }
            }
        }
    }
    var teamLeaderboard = userLeaderboard(userArray: [])
    @IBOutlet weak var users: UITableView!
    @IBOutlet weak var TeamTitle: UITextField!
    
    //Load & Appear Actions
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        teamLeaderboard.sortbyDistance()

        self.users.reloadData()

    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let userID = FIRAuth.auth()?.currentUser?.uid
        ref = FIRDatabase.database().reference()
        print("THIS IS LOAD PAGE")
        
        ref?.child("Users").child(userID!).child("Team").observeSingleEvent(of: .value, with: { (snapshot) in
            //get what team the user is part of so we can get the correct data from firbase
            let value = snapshot.value as? String
            print("value is \(String(describing: value))")
            
            self.team = value!

            //display the team name on the page
            self.TeamTitle.text = "Team " + self.team
            print("pulling users for team: \(self.team)")
            
            self.ref?.child("Teams").child(self.team).observeSingleEvent(of: .value, with: { snapshot in
                //print("calling database in viewLoader")
                let enumerator = snapshot.children
                while let rest = enumerator.nextObject() as? FIRDataSnapshot {
                    print("rest is \(rest)")
                    if rest.hasChildren(){
                        self.userKeys.append(rest.key)
                        //if a user was added update usercount
                        self.userCount += 1
                    }

                }
                
                for user in self.userKeys {
                        //create the userStats struct to store data
                        var newUser = userStats(kmRun: -1, timeRun: -1, username: "empty", userID: user)
                
                        self.ref?.child("Users").child(user).observeSingleEvent(of: .value, with: { snapshot in
                           // print("calling database in viewLoader")
                            let info = snapshot.value as? NSDictionary
                            print("\(info)")
                            let tempUsername = info?["username"]
                            let tempKM = info?["KMRun"]
                            let tempTime = info?["totalSeconds"]
                            print("filling user : \(newUser.userID)")
                            if tempUsername != nil{
                                
                                newUser.username = tempUsername as! String
                            } else{
                                print("couldn't find username")
                                print("tempUsername = \(tempUsername)")
                            }
                            if tempKM != nil{
                                newUser.kmRun = tempKM as! Double
                            }else{
                                print("couldn't find kmrun")
                                print("tempKM = \(tempKM)")
                            }
                            if tempTime != nil{
                                newUser.timeRun = tempTime as! Double
                            }else{
                                 print("couldn't find time")
                                print("tempTime = \(tempTime)")
                            }
                            print("--------")
                            print("adding user to table")
                            print("userID: \(newUser.userID)")
                            print("username: \(newUser.username)")
                            print("KmRun: \(newUser.kmRun)")
                            print("timeRun: \(newUser.timeRun)")
                            print("---------")
                            //once the user is filled out, add it to the teamleaderboard
                            self.teamLeaderboard.userArray.append(newUser)
                            

                    })

                }
                
                self.usersPopulated = true
                })

            self.users.reloadData()
            })
        
        

        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Functions
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cellToBeReturned: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "users")!
        
        ref = FIRDatabase.database().reference()
        
        print("THIS IS IT \(userKeys.count)")
        
       
        if usersPopulated{
            
            if sortByDistance {
                teamLeaderboard.sortbyDistance()
                
                cellToBeReturned.textLabel?.text = teamLeaderboard.userArray[indexPath.row].username
                cellToBeReturned.detailTextLabel?.text = "\(String(format: "%.2f", teamLeaderboard.userArray[indexPath.row].kmRun )) Km"
            }

            else {
                
                teamLeaderboard.sortByTime()
                cellToBeReturned.textLabel?.text = teamLeaderboard.userArray[indexPath.row].username
                let time: Int = Int(teamLeaderboard.userArray[indexPath.row].timeRun)
                let Minutes: Int = time / 60
                cellToBeReturned.detailTextLabel?.text =  "\(Minutes) : \(time%60)"



                
            }
        }

        
        return cellToBeReturned
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return userCount
    }
    

    
    //Actions
    
    @IBAction func BackButton(){
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func SwitchOrder(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 1 {
            sortByDistance = false
            teamLeaderboard.sortByTime()
            self.users.reloadData()
        }
        else{
            sortByDistance = true
            teamLeaderboard.sortbyDistance()
            self.users.reloadData()
        }
        
    }
    

}
