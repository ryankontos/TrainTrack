//
//  TrainTrackTabBarController.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 11/2/21.
//

import UIKit
import SwiftUI

class TrainTrackTabBarController: UITabBarController {
    
    
    override func viewDidLoad() {
        
        let trainList = UIHostingController(rootView: SetsList())
        trainList.tabBarItem = UITabBarItem(title: "Trains", image: UIImage(systemName: "tram.fill"), tag: 0)
        
        let tripList = UIHostingController(rootView: AllTripsView())
        tripList.tabBarItem = UITabBarItem(title: "Trips", image: UIImage(systemName: "line.horizontal.3.circle.fill"), tag: 1)
        
        
        self.viewControllers = [trainList, tripList]
        
    }

}
