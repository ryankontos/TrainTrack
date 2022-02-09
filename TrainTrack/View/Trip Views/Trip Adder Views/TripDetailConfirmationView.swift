//
//  TripDetailConfirmationView.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 15/1/21.
//

import SwiftUI

struct TripDetailConfirmationView: View {
    
    @State var notes = "Trip Notes"
    let placeholderString = "Trip Notes"
    
    var body: some View {
        
        Form {
            
            Section(header: Text("Confirm your new trip in N1717")) {
                

                TextEditor(text: self.$notes)
                          .foregroundColor(self.notes == placeholderString ? .gray : .primary)
                        
                
                
                }
            .onTapGesture {
              if self.notes == placeholderString {
                self.notes = ""
              }
            }
                .frame(width: 100, height: 300, alignment: .center)
                
                
            }
            
        
        
    }
}

struct TripDetailConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        TripDetailConfirmationView()
    }
}
