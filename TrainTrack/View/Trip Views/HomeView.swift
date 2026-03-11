//
//  HomeView.swift
//  TrainTrack Sydney
//
//  Created by Ryan on 15/4/2024.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
         
        NavigationStack {
            
            List {
                
                VStack(alignment: .leading) {
                    
                    Text("LATEST")
                    Text("N1717")
                    
                }
                
                
                Section {
                    
                    VStack(alignment: .leading) {
                        
                        Text("Trips")
                        
                        
                        HStack {
                            
                            Text("Today")
                            
                            Spacer()
                            
                            Text("10")
                            
                        }
                        
                        
                        
                    }
                    
                    
                }
                
                
            }
            .navigationTitle("TrainTrack")
            
        }
        
    }
}

#Preview {
    HomeView()
}
