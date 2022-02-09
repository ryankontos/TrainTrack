//
//  EnterCarriageView.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 20/11/20.
//

import SwiftUI
import Introspect

struct EnterCarriageView: View {
    
    enum FocusField: Hashable {
        case field
      }
    
    @EnvironmentObject var manager: EnteredCarriageManager
    
    @ObservedObject var trainFetcher = TrainFetcher.shared

    @Binding var showingSheet: Bool
    
    @State var contents: String = ""
    
    @State var showCam = true
    
    let cameraView = CameraViewController()
    
    @FocusState private var focusedField: FocusField?
    
    var body: some View {
        
            ZStack {

        Form {
            
            
            Section(header: Text("Enter Carriage Code")
                        .font(Font.system(size: 20, weight: .regular, design: .default))
                        .padding(.vertical, 10)
                        .textCase(.none)
                        .foregroundColor(Color(UIColor.label))
                        .multilineTextAlignment(.leading), content: {
                            
                TextField("Code", text: $manager.enteredText)
                                
                                
                    .padding(.horizontal, 10)
                            
                        })
            
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            
          
        }
        .safeAreaInset(edge: .bottom, content: {
            
            ZStack {
                
                VStack(spacing: 6) {
                
                    #if !targetEnvironment(macCatalyst)
                    
                    Button(action: { manager.showCamera = true }, label: {
                        
                        Label("Use Camera", systemImage: "camera.fill")
                        
                            .frame(height: 40)
                            .frame(maxWidth: .infinity)
                        
                    })
                        .tint(.blue)
                        .buttonStyle(.bordered)
                    
                    #endif
                        
                    
                    NavigationLink(isActive: $manager.pushTrainInfoView, destination: { EnteredCarriageResultParentView(showingSheet: $showingSheet, carriage: manager.enteredText)}, label: {
                    Text("Next")
                        .frame(height: 40)
                        .frame(maxWidth: .infinity)
                    
                })
                    
                    .buttonStyle(.borderedProminent)
                    .disabled(manager.enteredText.isEmpty)
        
                    
                }
                .padding(.all, 20)
                
                    .background {
                        
                        Rectangle()
                            .foregroundColor(Color(uiColor: .systemGroupedBackground))
                            .frame(maxWidth: .infinity)
                            .edgesIgnoringSafeArea(.bottom)
                        
                    }
                
            }
          
                
            
        })
            
     
            
            }
            .onAppear() {
                
                LocationManager.shared.updateLocationName()
                
                
                
            }
            
            .sheet(isPresented: $manager.showCamera, onDismiss: nil, content: {
                
                NavigationView {
                
                cameraView
                    
                    .environmentObject(manager)
                    
                    .navigationBarTitleDisplayMode(.inline)
                    .edgesIgnoringSafeArea(.bottom)
                    .toolbar {
                        
                        ToolbarItem(placement: .navigationBarLeading) {
                            
                            Button("Done", action: {
                                
                                manager.showCamera = false
                                
                            })
                            
                        }
                        
                    }
                    .introspectNavigationController { controller in
                        
                        controller.navigationBar.barStyle = .default
                    }
                    
                }
                
                
                    
                
            })
        
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle("New Trip")
            
        
        
        
    }
    
   
    
    
}
