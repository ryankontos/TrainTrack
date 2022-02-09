//
//  ContentView.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 19/11/20.
//

import SwiftUI
import Introspect

struct ContentView: View {
  
    @Environment(\.scenePhase) var phase
    
     var enteredCarriageManager = EnteredCarriageManager()
    
    @State var showCamera = false
    @State var showingModal = false
    
      var body: some View {
  
        TabView {
              
            SetsList()
                .tabItem {
                    
                    Image(systemName: "tram.fill")
                    Text("Trains") }
             
            
            AllTripsView()
                .tabItem {
                    
                    Image(systemName: "list.bullet.circle.fill")
                    Text("Trips")
                    
                }

            
          }
          
        .onAppear(perform: {
            
            
            
            AppShortcutItemManager.shared.setDelegate(self)
            
            
        })
          
          
           .safeAreaInset(edge: .bottom) {
            
                HStack {
                    
                    Spacer()
                    
                    Button(action: { showingModal = true }, label: {
                    
                        ZStack {
                           
                            Circle()
                                .foregroundColor(.blue.opacity(0.8))
                                .frame(width: 58, height: 58)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(.white)
                            
                        }
                        
                        
                    })
                        .padding(.bottom, 65)
                        .padding(.trailing, 20)
                    
                }
                
            }
           .sheet(isPresented: $showingModal, onDismiss: {
               
               
               enteredCarriageManager.enteredText = ""
               enteredCarriageManager.showCamera = false
               
           },content: {
               
               NavigationView {
               
                   EnterCarriageView(showingSheet: $showingModal)
                       .environmentObject(enteredCarriageManager)
                   .navigationBarItems(leading: Button("Cancel", action: {showingModal.toggle()}))
                   .navigationViewStyle(StackNavigationViewStyle())
                   .navigationBarTitleDisplayMode(.inline)
               
               }
               
               
           })
 
      }
    

    
   
    
}

extension ContentView: AppShortcutItemDelegate {
    func handle(shortcutItem: UIApplicationShortcutItem) {
        
        if (shortcutItem.userInfo?["name"] as? String) == "new" {
            showingModal = true
        }
        
        if (shortcutItem.userInfo?["name"] as? String) == "scan" {
            enteredCarriageManager.showCamera = true
            showingModal = true
        }
        
    }
    
    
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
