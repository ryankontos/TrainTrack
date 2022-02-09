//
//  TrainType.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 19/11/20.
//

import Foundation


protocol TrainType {
    var name: String { get }
}

struct Waratah: TrainType {
    var name = "Waratah"
}

struct Waratah2: TrainType {
    var name = "Waratah 2"
}

struct OSCAR: TrainType {
    var name = "OSCAR"
}

struct Millennium: TrainType {
    var name = "Millennium"
}

struct Tangara: TrainType {
    var name = "Tangara"
}

struct CSet: TrainType {
    var name = "C Set"
}

struct KSet: TrainType {
    var name = "K Set"
}

struct VSet: TrainType {
    var name = "V Set"
}

struct Endeavour: TrainType {
    var name = "Endeavour"
}

struct Hunter: TrainType {
    var name = "Hunter"
}

struct UnknownTrain: TrainType {
    var name = "Unknown"
}


