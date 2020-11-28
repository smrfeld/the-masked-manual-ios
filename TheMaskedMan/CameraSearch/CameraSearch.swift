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

extension String {
    func no_spaces() -> Int {
        return self.components(separatedBy: " ").count - 1
    }
}

protocol CameraSearchProtocol {
    mutating func update_candidates_with_observations(raw_observed_texts : [String])
    func get_top_mask_or_company() -> (Mask?, Company?)
}

struct CameraSearch : CameraSearchProtocol {
    
    private var masks : [Mask] = []
    private var companies : [Company] = []
    private var model_candidates : [Mask : MyCandidate] = [:]
    private var company_candidates : [Company : MyCandidate] = [:]
    private let observed_texts = ObservedTexts()

    init(masks : [Mask], companies : [Company]) {
        self.masks = masks
        self.companies = companies
    }
    
    mutating func update_candidates_with_observations(raw_observed_texts : [String]) {
        
        // Ammend and fix list of candidates
        let ret = observed_texts.get_observed_texts(raw_observed_texts: raw_observed_texts)
                
        add_observations_for_models(observed_texts: ret.0)
        add_observations_for_companies(observed_texts: ret.1)
    }
    
    func get_top_mask_or_company() -> (Mask?, Company?) {
        
        print_top_mask_by_model_and_company()
        print_top_company()
        
        // Find the top mask purely by both the mask factor and the company factor
        let top = model_candidates.max(by: { (m1, m2) -> Bool in
            return m1.value.get_weight() < m2.value.get_weight()
        })
        
        // Check sufficient weight
        if let top = top, top.value.get_weight() > 0.6 {
            return (top.key, nil)
        } else {
            
            // Possibly good enough guess for company
            // Find top company
            let top_company = company_candidates.max { (c1, c2) -> Bool in
                return c1.value.get_weight() < c2.value.get_weight()
            }
            
            if let top_company = top_company, top_company.value.get_weight() > 0.6 {
                return (nil, top_company.key)
            } else {
            
                // Truly nothing found
                return (nil, nil)
            }
        }
    }
    
    private func print_top_mask_by_model_and_company() {
        
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

    private func print_top_company() {
        
        let cs = company_candidates.sorted { (c1, c2) -> Bool in
            return c1.value.get_weight() > c2.value.get_weight()
        }
        
        print("Top 3 company candidates:")
        var i = 0
        for (company, candidate) in cs {
            print(company.name, " ~ ", company.search_name, ": weight: ", candidate.get_weight())
            
            i += 1
            if i == 3 {
                break
            }
        }
    }
    
    private func collect_unnormalized_weights_for_models(observed_texts : [String]) -> [Mask : Float] {
        
        var weights : [Mask : Float] = [:]
        for observed_text in observed_texts {
            
            let masks_filtered = masks.filter({ (mask) -> Bool in
                return mask.search_model.contains(observed_text)
            })
            print("--- ", observed_text, " is in: ", masks_filtered.map({ (m) -> String in
                return m.search_model
            }))
            
            for mask in masks_filtered {
                let weight = Float(observed_text.count)
                if weights[mask] == nil {
                    weights[mask] = 0.0
                }
                weights[mask]! += weight
            }
        }
        
        return weights
    }

    private func collect_unnormalized_weights_for_companies(observed_texts : [String]) -> [Company : Float] {
        
        var weights : [Company : Float] = [:]
        for observed_text in observed_texts {
            
            let companies_filtered = companies.filter({ (company) -> Bool in
                return company.search_name.contains(observed_text)
            })
            
            for company in companies_filtered {
                let weight = Float(observed_text.count)
                if weights[company] == nil {
                    weights[company] = 0.0
                }
                weights[company]! += weight
            }
        }
        
        return weights
    }
    
    private func normalize_weights(weights : inout [Mask : Float]) {
        
        // Normalize by the highest number if exists
        // Why?
        // Matching observation -> correct mask name:
        // "3m" -> "3m" is good
        // "guangzhou powecom labr" -> "guangzhou powecom labor" should be higher even though labr is wrong
        // This rewards longer matches
        if let max_weight = weights.values.max() {
            weights = weights.mapValues { (weight) -> Float in
                return weight / max_weight
            }
        }
    }

    private func normalize_weights(weights : inout [Company : Float]) {
        
        // Normalize by the highest number if exists
        // Why?
        // Matching observation -> correct mask name:
        // "3m" -> "3m" is good
        // "guangzhou powecom labr" -> "guangzhou powecom labor" should be higher even though labr is wrong
        // This rewards longer matches
        if let max_weight = weights.values.max() {
            weights = weights.mapValues { (weight) -> Float in
                return weight / max_weight
            }
        }
    }

    private mutating func ensure_candidates_exist_for_mask(weights : [Mask : Float]) {
        
        // Ensure all observed masks have a candidate
        for (mask, _) in weights {
            if model_candidates[mask] == nil {
                // Add
                model_candidates[mask] = MyCandidate()
            }
            
            // Also add the company!
            if let company = mask.company_obj {
                if company_candidates[company] == nil {
                    company_candidates[company] = MyCandidate()
                }
            }
        }
    }

    private mutating func ensure_candidates_exist_for_company(weights : [Company : Float]) {
        
        // Ensure all observed masks have a candidate
        for (company, _) in weights {
            if company_candidates[company] == nil {
                company_candidates[company] = MyCandidate()
            }
        }
    }
    
    private mutating func add_observations_for_models(observed_texts : [String]) {
        
        // Collect weights
        var weights = collect_unnormalized_weights_for_models(observed_texts: observed_texts)
        normalize_weights(weights: &weights)
        
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
    
    private mutating func add_observations_for_companies(observed_texts : [String]) {
        
        // Collect weights
        var weights = collect_unnormalized_weights_for_companies(observed_texts: observed_texts)
        normalize_weights(weights: &weights)
        
        // Ensure all observed masks have a candidate
        ensure_candidates_exist_for_company(weights: weights)
        
        // Add observations for all candidates
        for (company_candidate, candidate) in company_candidates {
            if let weight = weights[company_candidate] {
                // There exists an observation for this candidate
                candidate.add_observation(weight)
            } else {
                // No observation right now
                // "Expire" old observations i.e. get smaller = less important
                candidate.expire_observations_if_exist()
            }
        }
    }
}
