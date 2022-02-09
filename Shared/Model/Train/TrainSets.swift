//
//  TrainSets.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 19/11/20.
//

import Foundation

class TrainSets: ObservableObject {
    
    @Published var sets = [TrainSet]()
    
    static var shared = TrainSets()
    
    init() {
        
        self.update()
        
    }
    
    func update() {
        
        TrainFetcher.shared.update()
        
        let newSets = generateSets(from: TrainFetcher.shared.trains)
        
        if newSets != self.sets {
            self.sets = newSets
        }
        
        
        
    }
    
    func updateAsync() {
        
        
            self.update()
        
        
    }
    
    private func buildSets() -> [TrainSet] {
        
        var tempSets = [TrainSet]()
        
        tempSets.append(TrainSet(setName: "Waratah 2", setCodeLetter: "B"))
        tempSets.append(TrainSet(setName: "Waratah", setCodeLetter: "A"))
        tempSets.append(TrainSet(setName: "OSCAR", setCodeLetter: "H"))
        tempSets.append(TrainSet(setName: "Millennium", setCodeLetter: "M"))
        tempSets.append(TrainSet(setName: "Tangara", setCodeLetter: "T"))
        tempSets.append(TrainSet(setName: "C Set", setCodeLetter: "C"))
        tempSets.append(TrainSet(setName: "K Set", setCodeLetter: "K"))
        tempSets.append(TrainSet(setName: "V Set", setCodeLetter: "V"))
        tempSets.append(TrainSet(setName: "Endeavour", setCodeLetter: "N"))
        tempSets.append(TrainSet(setName: "Hunter", setCodeLetter: "J"))
        
        return tempSets
        
    }
    
    func generateSets(from trains: [Train]) -> [TrainSet] {
        
      let tempSets = buildSets()
        
        for train in trains {
            
            for set in tempSets {
                
                if train.name.prefix(1) == set.setCodeLetter {
                    set.trains.append(train)
                }
                
                
            }
            
            
        }
        
        var finalSets = [TrainSet]()
        
        for ts in tempSets {
            
            if !ts.trains.isEmpty {
                finalSets.append(ts)
            }
            
        }
        
        return finalSets
        
    }
    
    func matchSet(to train: Train) -> TrainSet? {
        
       
        let tempSets = buildSets()
        
            for set in tempSets {
                
                if train.name.prefix(1) == set.setCodeLetter {
                    return set
                }
                
                
            }
            
        
        return nil
        
    }
    
    func previewSet() -> TrainSet {
        
        return sets.first!
        
    }
    
}


class TrainSet: Identifiable, Equatable {
    static func == (lhs: TrainSet, rhs: TrainSet) -> Bool {
        return lhs.setName == rhs.setName
        
    }
    
    
    internal init(setName: String, setCodeLetter: String) {
        self.setName = setName
        self.setCodeLetter = setCodeLetter
    }
    
    
    var setName: String
    var setCodeLetter: String
    var trains = [Train]()
    
    var riddenTrains: [Train] {
        
        get {
            
            trains.filter({$0.trips.count > 0})
            
        }
        
    }
    
}
