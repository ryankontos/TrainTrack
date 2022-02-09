//
//  SetTrainListItem.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 20/11/20.
//

import SwiftUI

struct SetTrainListItem: View {
    
    @State var train: Train
    
    @State var color: Color
    
    var body: some View {

        HStack(alignment: .center, spacing: 12) {
        
           Circle()
            .foregroundColor(circleColor)
            .frame(width: 47, height: 47, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
            .overlay(getOverlay())
            
        VStack(alignment: .leading, spacing: 3) {
           
            
            Text(train.name)
                .font(Font.system(size: 21, weight: .medium, design: .default))
            Text(tripsString)
                .font(Font.system(size: 17 , weight: .regular, design: .default))
                .foregroundColor(.secondary)
            
            
        }
                
        Spacer()
                
        
        }
        .padding(.horizontal, 0)
        .padding(.vertical, 10)

        
        
        
        
    }
    
    var circleColor: Color {
        
        if train.trips.isEmpty {
            
            return Color(UIColor.gray).opacity(0.7)
            
        } else {
            
            return Color(UIColor.green)
            
        }
        
        
    }
    

    func getOverlay() -> AnyView {
        
        if !train.trips.isEmpty {
            
            return AnyView(
                Image(systemName: "checkmark")
                    .font(Font.system(size: 19, weight: .medium, design: .default))
                    .foregroundColor(.white)
            
            )
            
        } else {
            
            return AnyView(EmptyView())
            
        }
        
    }
    
    var tripsString: String {
        
        var plural = "Trip"
        if train.trips.count != 1 {
            plural += "s"
        }
        
        return "\(train.trips.count) \(plural)"
        
        
    }
    
}

/*struct SetTrainListItem_Previews: PreviewProvider {
    static var previews: some View {
        SetTrainListItem(train: <#Train#>)
    }
}*/
