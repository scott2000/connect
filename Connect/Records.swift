//
//  Records.swift
//  Connect
//
//  Created by Scott Taylor on 6/5/16.
//  Copyright © 2016 Scott Taylor. All rights reserved.
//

import Foundation

class Records {
    var chain: Int
    var points: Int
    
    init(s: String?) {
        if (s == nil) {
            chain = 0
            points = 0
        } else {
            let data = s!.components(separatedBy: ".")
            chain = Int(data[0]) ?? 0
            points = Int(data[1]) ?? 0
        }
    }
    
    func save() -> String {
        return "\(chain).\(points)"
    }
    
    func chain(length: Int) {
        if (length > chain) {
            print("Chain Record: \(length)")
            chain = length
        }
    }
    
    func points(amount: Int) {
        if (amount > points) {
            print("Points Record: \(amount)")
            points = amount
        }
    }
}
