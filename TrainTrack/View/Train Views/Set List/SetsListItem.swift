//
//  SetsListItem.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 19/11/20.
//

import SwiftUI

struct SetsListItem: View {
    
    @State var set: TrainSet
    
    var body: some View {
        
        HStack(alignment: .center, spacing: 15) {
            
            
        Image(set.setName)
            .resizable()
            .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
            .aspectRatio(contentMode: ContentMode.fill)
            .frame(width: 55, height: 55)
            .overlay(
  
                
                ProgressRing(progress: Float(Float(set.riddenTrains.count)/Float(set.trains.count)))
                    .scaleEffect(1.12)
                    
                
                    
            )
            
        VStack(alignment: .leading, spacing: 3) {
            
            Text(set.setName)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .font(Font.system(size: 22, weight: .medium, design: .default))
            Text("\(set.riddenTrains.count)/\(set.trains.count) Ridden")
                .font(Font.system(size: 16, weight: .regular, design: .default))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            
        }
                
        Spacer()
        
        }
        .padding(.vertical, 15)
  
    }
}

/*struct SetsListItem_Previews: PreviewProvider {
    static var previews: some View {
        SetsListItem(set: TrainSets().sets.first!)
    }
}
*/
