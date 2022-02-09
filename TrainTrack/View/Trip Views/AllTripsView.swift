//
//  AllTripsView.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 19/11/20.
//

import SwiftUI
import MapKit

struct AllTripsView: View {
    
    @ObservedObject var trainFetcher = TrainFetcher.shared
    
    
    @ObservedObject var trainSets = TrainSets()
    
    @State var filters = [TrainSet]()
    
    let lookup = TrainLookup()
    
    @ObservedObject var model = AllTripsViewModel()
    
    let selectedFilterName = "line.horizontal.3.decrease.circle.fill"
    let filterName = "line.horizontal.3.decrease.circle"
    
    var body: some View {
        
        NavigationView {
        
        List {
            
            /*
            
            Section(header:
                        
                NewTripButtonView(toggled: $showingModal)
                       
            
            ) {
                
                EmptyView()
                
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .headerProminence(.increased)
            
            */
            
            ForEach(model.tripGroups, id: \.self, content: { tripGroup in
                
                Section(header: Text(tripGroup.date.userFriendlyRelativeString())) {
                    
                    ForEach(tripGroup.trips, id: \.self, content: { trip in
                    
                        NavigationLink(destination: TrainDetailView(carriage: nil, train: lookup.findTrain(withCarriage: trip.carriageCode, from: trainFetcher.trains)!, showingSheet: .constant(false))) {
                        
                        TripRowView(trip: trip, showDate: false)
                            
                    }
                        
                    }
                    
                    )}
                
            })
            
            .onDelete(perform: { indexSet in
                
                indexSet.forEach { index in
                    
                    let trip = TripFetcher.shared.trips[index]
                    
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    let context = TTCloudKit.shared.persistentContainer.viewContext
                    
                    context.delete(trip.baseStoredTrip)
                    try? context.save()
                    
                    TripFetcher.shared.updateTrips()
                    
                    
                }
                
            })
            
            }
        .overlay {
            
            if model.tripGroups.isEmpty {
                Text("No Trips")
                    .foregroundColor(.secondary)
            }
            
        }
        
        .onAppear() {
            
            TripFetcher.shared.updateTrips()
            
        }
            
        .toolbar(content: {
            

            
            ToolbarItem(placement: .navigationBarTrailing) {
                
                Menu(content: {
                    
                    ForEach(trainSets.sets) { trainSet in
                        
                        Button(action: { withAnimation { toggleFilter(trainSet: trainSet) } }, label: {
                            
                            HStack {
                               
                                Text(trainSet.setName)
                                Spacer()
                                
                                if model.filters.contains(trainSet) {
                                    Image(systemName: "checkmark")
                                }
                                
                            }
                            
                            })
                        
                    }
                    
                    Divider()
                    
                    if !model.filters.isEmpty {
                        
                        Button(role: .destructive, action: { model.filters.removeAll() }, label: { Text("Clear Filters") })
                        
                        
                    }
                    
                    
                }, label: {
                    
                    HStack {
                        
                        Image(systemName: model.filters.isEmpty ? filterName : selectedFilterName)
                        
                        if !model.filters.isEmpty {
                            Text(String(model.filters.count))
                        }
                        
                    }
                    
                })
                
            }
                
            
            
        })
        
        .navigationTitle("Trips (\(model.tripGroups.map({$0.trips}).count))")
            
        }.listStyle(.insetGrouped)
        
          
        }
    
    
    func toggleFilter(trainSet: TrainSet) {
        
        if model.filters.contains(trainSet) {
            model.filters.removeAll(where: { $0 == trainSet })
        } else {
            model.filters.append(trainSet)
        }
        
    }
    

}

struct AllTripsView_Previews: PreviewProvider {
    static var previews: some View {
        AllTripsView()
    }
}

class AllTripsViewModel: ObservableObject {
    
    let lookup = TrainLookup()
    
    @Published var tripGroups: [TripGroup]
    
    @Published var filters = [TrainSet]() {
     
        didSet {
            
            updateGroups()
            
        }
        
    }
    
    init() {
        
        tripGroups = TripFetcher.shared.tripGroups
        updateGroups()
    }
    
    
    func updateGroups() {
        
        let groups = TripFetcher.shared.tripGroups
        
        if filters.isEmpty {
            tripGroups = groups
            return
            
        }
        
        var newGroups = [TripGroup]()
        
        for group in groups {
            
            var trips = [Trip]()
            
            for trip in group.trips {
                
                guard let train = lookup.findTrain(withCarriage: trip.carriageCode, from: TrainFetcher.shared.trains) else { continue }
                guard let set = TrainSets.shared.matchSet(to: train) else { continue }
                print("Set: \(set.setName)")
                if filters.contains(set) {
                    print("Appending trip")
                    trips.append(trip)
                    
                }
                
            }
            
            if !trips.isEmpty {
                
                let newGroup = group
                group.trips = trips
                newGroups.append(newGroup)
                
            }
            
            
        }
        
        tripGroups = newGroups
        
        
    }
    
    
    
}
