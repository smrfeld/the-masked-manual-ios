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
    
    private var masks : [Mask] = []
    private var companies : [Company] = []
    private var model_candidates : [Mask : MyCandidate] = [:]
    private var company_candidates : [Company : MyCandidate] = [:]

    init(masks : [Mask], companies : [Company]) {
        self.masks = masks
        self.companies = companies
    }
    
    mutating func update_candidates_with_observations(raw_observed_texts : [String]) {
        
        // Ammend and fix list of candidates
        let observed_texts = ammend_raw_observed_texts(raw_observed_texts: raw_observed_texts)
        
        // print("Observed texts: ", observed_texts)
        
        add_observations_for_model(observed_texts: observed_texts)
    }
    
    private mutating func add_observations_for_model(observed_texts : [String]) {
        
        // Collect weights
        var weights : [Mask : Float] = [:]
        for observed_text in observed_texts {
            
            let masks_filtered = masks.filter({ (mask) -> Bool in
                return mask.search_model.contains(observed_text)
            })
            
            for mask in masks_filtered {
                // Min weight = 0
                // Max weight = 1 => all of the name was found, i.e. the two match exactly
                // Square to skew the distribution
                let weight = pow(Float(observed_text.count) / Float(mask.search_model.count), 2)
                if weights[mask] == nil {
                    weights[mask] = 0.0
                }
                weights[mask]! += weight
            }
        }
        
        // Ensure all observed masks have a candidate
        for (mask, _) in weights {
            if model_candidates[mask] == nil {
                model_candidates[mask] = MyCandidate()
            }
        }
        
        // Add observations for all candidates
        for (mask_candidate, candidate) in model_candidates {
            if let weight = weights[mask_candidate] {
                // There exists an observation for this candidate
                candidate.add_observation(weight)
            } else {
                // No observation right now
                // "Expire" old observations i.e. get smaller = less important
                candidate.expire_observations_if_exist()
            }
        }
    }
    
    func get_top_mask_or_company() -> (Mask?, Company?) {
        
        let ms = model_candidates.sorted { (m1, m2) -> Bool in
            return m1.value.get_weight() > m2.value.get_weight()
        }
        print("Top 3 mask candidates:")
        var i = 0
        for (mask, candidate) in ms {
            print(mask.company, ": ", mask.model, " ~ ", mask.search_model, ": ", candidate.get_weight())
            
            i += 1
            if i == 3 {
                break
            }
        }
        
        // Find the top mask purely by both the mask factor and the company factor
        let top_mask = model_candidates.max(by: { (m1, m2) -> Bool in
            return m1.value.get_weight() < m2.value.get_weight()
        })
        
        if let tm = top_mask?.key, let tmc = top_mask?.value, tmc.get_weight() > 5.0 {
            return (tm, nil)
        } else {
            return (nil, nil)
        }
    }
    
    private func ammend_raw_observed_texts(raw_observed_texts : [String]) -> [String] {
        var candidates = raw_observed_texts
        
        // Get search words
        // Removes nonsense characters and trivial phrases
        candidates = candidates.map({ (c) -> String in
            return ModelSearchName.get_search_model_name(model_name: c)
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
