//
//  SetTrainList.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 20/11/20.
//

import SwiftUI

struct SetTrainList: View {

    @State var showRiddenOnly = false
    
    var set: TrainSet
    
   
    
    let selectedFIlterName = "line.horizontal.3.decrease.circle.fill"
    let filterName = "line.horizontal.3.decrease.circle"
    
    var body: some View {
        
        Group {
        
        List {
            Section {
                ForEach(trains, content: { train in
                    NavigationLink(destination: TrainDetailView(train: train, showingSheet: .constant(false))) {
                        SetTrainListItem(train: train, color: computeColor(for: train))
                    }
                })
            }
        }
       
        }
        .toolbar(content: {
            
            #if os(iOS)
            
            
            ToolbarItem(placement: .navigationBarTrailing, content: {
                
                Button(action: { showRiddenOnly.toggle() }, label: { Image(systemName: showRiddenOnly ? selectedFIlterName : filterName) })
                    
            })
            
            #endif
            
            
        })
        
        .animation(.default, value: showRiddenOnly)
        #if os(iOS)
        .listStyle(.insetGrouped)
        #endif
        .navigationTitle("\(set.setName)")
        
        
        
    }

    var trains: [Train] {
        
        get {
            
            if !showRiddenOnly {
                return set.trains
            }
            
            return set.trains.filter({$0.isRidden})
            
        }
        
    }
    
    func computeColor(for train: Train) -> Color {
        
        if train.trips.count > 0 {
            
            return Color(#colorLiteral(red: 0.00860242509, green: 1, blue: 0, alpha: 0.43))
            
        } else {
            
            #if os(iOS)
            
            return Color(UIColor.secondarySystemGroupedBackground)
            
            #else
            
            return Color.gray
            
            #endif
            
        }
        
    }
    
    func getFilterButton() -> Image {
        
        if showRiddenOnly {
            
            return Image(systemName: "line.horizontal.3.decrease.circle.fill")
            
        } else {
            
            return Image(systemName: "line.horizontal.3.decrease.circle")
            
        }
        
    }
}

struct SetTrainList_Previews: PreviewProvider {
    static var previews: some View {
        SetTrainList(set: TrainSets().previewSet())
           
    }
}
