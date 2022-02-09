//
//  SetsList.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 19/11/20.
//

import SwiftUI

struct SetsList: View {
    
    @ObservedObject var trainSets = TrainSets()
   
    
    @State var popoverShown = false
    
    @State var searchText = ""
    
    var body: some View {
        
        NavigationView {
            
            List {
                    
                ForEach(trainSets.sets, content: { set in
                        
                    NavigationLink(destination: SetTrainList(set: set).environmentObject(trainSets)) {
                            
                        SetsListItem(set: set)
                            
                    }
                        
                        
                })
                
            }
            
            #if os(watchOS)
            .listStyle(.automatic)
            #else
            .listStyle(.insetGrouped)
            #endif
            
            
            .navigationTitle("Trains")
     
            
        }
        
    }
    
   
    
    
}

struct SetsList_Previews: PreviewProvider {
    static var previews: some View {
        SetsList()
    }
}
