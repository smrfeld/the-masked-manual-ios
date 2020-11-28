//
/*
File: Candidates.swift
Created by: Oliver K. Ernst
Date: 11/26/20

MIT License

Copyright (c) 2020 Oliver K. Ernst

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/ 

import Foundation

private let no_observations = 10

open class MyCandidate : Hashable {

    let uuid = UUID().uuidString
    var weights : [Float] = []

    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }

    public static func == (lhs: MyCandidate, rhs: MyCandidate) -> Bool {
        return lhs.uuid == rhs.uuid
    }
            
    func expire_observations_if_exist() {
        // All observations reduced by a factor
        if weights.count > 0 {
            weights = weights.map { (x) -> Float in
                return 0.99 * x
            }
        }
    }
    
    private func ensure_less_than_max_no_observations() {
        while weights.count > no_observations {
            weights.removeFirst()
        }
    }
    
    func get_weight() -> Float {
        ensure_less_than_max_no_observations()
        
        if weights.count == no_observations {
            return weights.reduce(0, +) / Float(no_observations)
        } else {
            return 0
        }
    }
    
    func add_observation(_ weight : Float) {
        if weight != 0 {
            weights.append(weight)
        }
        
        ensure_less_than_max_no_observations()
    }
    
    func has_min_no_occurences() -> Bool {
        return weights.count == no_observations
    }
}
