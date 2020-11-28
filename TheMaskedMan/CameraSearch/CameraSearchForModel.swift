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

protocol CameraSearchForModelProtocol {
    mutating func update_candidates_with_observations(observed_texts : [String])
    func get_top_mask(min_weight : Float) -> Mask?
}

struct CameraSearchForModel : CameraSearchForModelProtocol {
    
    private var masks : [Mask] = []
    private var model_candidates : [Mask : MyCandidate] = [:]

    init(masks : [Mask]) {
        self.masks = masks
    }
    
    mutating func update_candidates_with_observations(observed_texts : [String]) {
        
        // Collect weights
        let weights = collect_normalized_weights_for_models(observed_texts: observed_texts)
        
        // Ensure all observed masks have a candidate
        ensure_candidates_exist_for_mask(weights: weights)
        
        // Add observations for all candidates
        for (mask_candidate, model_candidate) in model_candidates {
            if let weight = weights[mask_candidate] {
                // There exists an observation for this candidate
                model_candidate.add_observation(weight)
            } else {
                // No observation right now
                // "Expire" old observations i.e. get smaller = less important
                model_candidate.expire_observations_if_exist()
            }
        }
    }
    
    func get_top_mask(min_weight : Float = 0.5) -> Mask? {
                
        // Find the top mask purely by both the mask factor and the company factor
        let top = model_candidates.max(by: { (m1, m2) -> Bool in
            return m1.value.get_weight() < m2.value.get_weight()
        })
        
        // Check sufficient weight
        if let top = top, top.value.get_weight() > min_weight {
            return top.key
        } else {
            // Truly nothing found
            return nil
        }
    }
    
    private func print_top_mask() {
        
        let ms = model_candidates.sorted { (m1, m2) -> Bool in
            return m1.value.get_weight() > m2.value.get_weight()
        }
        
        print("Top 3 mask candidates by model:")
        var i = 0
        for (mask, model_candidate) in ms {
            print(mask.company, ": ", mask.model, " ~ ", mask.search_model, ": weight: ", model_candidate.get_weight())
            
            i += 1
            if i == 3 {
                break
            }
        }
    }
    
    private func collect_normalized_weights_for_models(observed_texts : [String]) -> [Mask : Float] {
        
        var weights : [Mask : Float] = [:]
        for observed_text in observed_texts {
            
            // Any substring contains the observed text
            let masks_filtered = masks.filter({ (mask) -> Bool in
                return mask.search_model.contains(observed_text)
            })
            
            /*
            print("--- ", observed_text, " is in: ", masks_filtered.map({ (m) -> String in
                return m.search_model
            }))
             */
            
            for mask in masks_filtered {
                // Percentage of model captured
                // Min is 0
                // Max is 1
                let weight = Float(observed_text.count) / Float(mask.search_model.count)
                if weights[mask] == nil {
                    weights[mask] = 0.0
                }
                weights[mask]! = max(weight, weights[mask]!)
            }
        }
        
        return weights
    }

    private mutating func ensure_candidates_exist_for_mask(weights : [Mask : Float]) {
        
        // Ensure all observed masks have a candidate
        for (mask, _) in weights {
            if model_candidates[mask] == nil {
                model_candidates[mask] = MyCandidate()
            }
        }
    }
}
