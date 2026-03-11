//
//  GraphViews.swift
//  TrainTrack Sydney
//
//  Created by Ryan Kontos on 3/8/2022.
//
/*
import SwiftUI
import Charts

struct GraphViews: View {
    
    let dataGen = GraphDataGenerator()
    
    var body: some View {
        
        GeometryReader { proxy in
            
            Chart {
                ForEach(dataGen.getTripPeriods()) { period in
                    BarMark(
                        x: .value("Period", period.periodName),
                        y: .value("Count", period.tripCount)
                        
                        
                        
                    )
                    .foregroundStyle([Color.red, Color.cyan, Color.pink, Color.mint].randomElement()!)
                    .annotation(content: {
                        
                        Text(String(period.tripCount))
                    })
                    
                    
                    
                }
            }
            .padding(.bottom, 90)
            .padding(.top, 20)
            
            
            .frame(width: proxy.size.width)
            
        }
    }
}

struct GraphViews_Previews: PreviewProvider {
    static var previews: some View {
        GraphViews()
    }
}

struct TripPeriod: Identifiable {
    
    
    var periodID: Int
    var periodName: String
   // var setName: String
    
    var tripCount: Int
    
    var id = UUID()
    
}

struct GraphDataGenerator {
    
    
    
    func getTripPeriods() -> [TripPeriod] {
        
        let setFetcher = TrainSets()
        
        var periods = [TripPeriod]()
        
        let trips = TripFetcher.shared.getTrips().reversed()
        
        for trip in trips {
            
            
            
            let periodString = getDateString(date: trip.date)
            /*guard let setString = setFetcher.matchTripToSetName(trip: trip) else {
                continue
            }*/
            
            print("Get with \(trip.carriageCode)")
            
            if let index = periods.firstIndex(where: { $0.periodName == periodString }) {
                
                var itemCopy = periods[index]
                itemCopy.tripCount += 1
                periods[index] = itemCopy
                
            } else {
                
                let item = TripPeriod(periodID: getDateID(date: trip.date), periodName: periodString, tripCount: 1)
                periods.append(item)
                
            }
            
        }
        
        periods = periods.sorted(by: { $0.periodID > $1.periodID }).reversed()
        return periods
        
        
    }
    
    
    func getDateID(date: Date) -> Int {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "e"
        return Int(dateFormatter.string(from: date))!
        
    }
    
    func getDateString(date: Date) -> String {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE"
        return dateFormatter.string(from: date)
        
    }
    
}
*/
