//
/*
File: CameraSearch.swift
Created by: Oliver K. Ernst
Date: 11/24/20

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

private class ModelCandidate : Hashable {
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }

    static func == (lhs: ModelCandidate, rhs: ModelCandidate) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
    let uuid = UUID().uuidString
    let mask : Mask
    var weights : [Float] = []
    
    init(_ mask : Mask) {
        self.mask = mask
    }
    
    func expire_observations_if_exist() {
        // All observations reduced by a factor
        if weights.count > 0 {
            weights = weights.map { (x) -> Float in
                return 0.9 * x
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
            return weights.reduce(0, +)
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

struct CameraSearch {
        
    private var mask_candidates : [ModelCandidate] = []

    init(_ masks : [Mask]) {
        for mask in masks {
            mask_candidates.append(ModelCandidate(mask))
        }
    }
    
    func update_candidates_with_observations(raw_observed_texts : [String]) {
        
        // Ammend and fix list of candidates
        let observed_texts = ammend_candidates(raw_candidates: raw_observed_texts)
        
        // print("Observed texts: ", observed_texts)
        
        // Collect weights
        var weights : [ModelCandidate : Float] = [:]
        for observed_text in observed_texts {
            
            let candidates_filtered = mask_candidates.filter({ (mask) -> Bool in
                return mask.mask.search_model.contains(observed_text)
            })
            
            for cf in candidates_filtered {
                // Min weight = 0
                // Max weight = 1 => all of the name was found, i.e. the two match exactly
                // Square to skew the distribution
                let weight = pow(Float(observed_text.count) / Float(cf.mask.search_model.count), 2)
                if weights[cf] == nil {
                    weights[cf] = 0.0
                }
                weights[cf]! += weight
            }
        }
        
        // Add observations
        for candidate in mask_candidates {
            if let weight = weights[candidate] {
                candidate.add_observation(weight)
            } else {
                // No observation right now
                // Check if there are any observations; if there are, these need to "expire" i.e. get smaller = less important
                candidate.expire_observations_if_exist()
            }
        }
    }
    
    func get_top_mask() -> Mask? {
        return mask_candidates.max(by: { (m1, m2) -> Bool in
            return m1.get_weight() < m2.get_weight()
        })?.mask
    }
    
    private func ammend_candidates(raw_candidates : [String]) -> [String] {
        var candidates = raw_candidates
        
        // Get search words
        // Removes nonsense characters and trivial phrases
        candidates = candidates.map({ (c) -> String in
            return get_search_name(c)
        })
        
        // Remove anything less than 2 characters
        var i = 0
        while i < candidates.count {
            if candidates[i].count < 2 {
                candidates.remove(at: i)
            } else {
                i += 1
            }
        }
        
        // Add all words
        for i in 0..<candidates.count {
            let words = candidates[i].components(separatedBy: " ")
            
            // Only add words if more than one word
            if words.count != 1 {
                for word in words {
                    // Only add if the word has more than 2 characters
                    if word.count >= 2 {
                        candidates.append(word)
                    }
                }
            }
        }
        
        // For every candidate, also try stripping any leading or trailing zeros if they exist
        for i in 0..<candidates.count {
            if candidates[i].first! == "0" {
                candidates.append(String(candidates[i].dropFirst()))
            }
            
            if candidates[i].last! == "0" {
                candidates.append(String(candidates[i].dropLast()))
            }
        }
        
        // Remove duplicates (ruins ordering!)
        candidates = Array(Set(candidates))
        
        return candidates
    }
}
