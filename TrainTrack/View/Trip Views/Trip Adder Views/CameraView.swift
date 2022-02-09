//
//  CameraView.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 23/1/2022.
//

import SwiftUI


struct CameraViewController: UIViewControllerRepresentable {
    
    @EnvironmentObject var manager: EnteredCarriageManager
    
    init() {
        
        print("Init camera view")
        
        
            visionController = (storyboard.instantiateInitialViewController() as! VisionViewController)
        
        
        
        visionController.setup()
        
        
    }
   
    var visionController: VisionViewController!
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    let storyboard = UIStoryboard(name: "CameraView", bundle: .main)

    func makeUIViewController(context: Context) -> VisionViewController {
        
        visionController.delegate = context.coordinator
        return visionController
        
    }

    func updateUIViewController(_ controller: VisionViewController, context: Context) {
        
    }
    
    class Coordinator: NSObject {
        
        internal init(_ parent: CameraViewController) {
            self.parent = parent
        }
        
        func gotText(_ text: String) {
            
            self.parent.manager.gotFullCarriageCodeExternally(code: text)
            
            DispatchQueue.main.async {
                self.parent.manager.showCamera = false
            }
            
        }
        
        var parent: CameraViewController
        
    }


}
