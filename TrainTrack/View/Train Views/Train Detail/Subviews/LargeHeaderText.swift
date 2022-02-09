//
//  LargeHeaderText.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 8/1/21.
//

import SwiftUI

struct LargeHeaderText: View {
    
    @State var text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 20, weight: .semibold, design: .default))
            
            .textCase(.none)
            .padding(.bottom, 3)
        
    }
    
    
}

struct LargeHeaderText_Previews: PreviewProvider {
    static var previews: some View {
        LargeHeaderText(text: "Text")
    }
}
