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

protocol CameraSearchProtocol {
    mutating func update_candidates_with_observations(raw_observed_texts : [String])
    func get_top_mask_or_company() -> (Mask?, Company?)
}

struct CameraSearch : CameraSearchProtocol {
    
    private var masks : [Mask] = []
    private var companies : [Company] = []
    private var model_candidates : [Mask : ModelCandidate] = [:]
    private var company_candidates : [Company : MyCandidate] = [:]

    init(masks : [Mask], companies : [Company]) {
        self.masks = masks
        self.companies = companies
    }
    
    mutating func update_candidates_with_observations(raw_observed_texts : [String]) {
        
        // Ammend and fix list of candidates
        let observed_texts = ObservedTexts(raw_observed_texts: raw_observed_texts).observed_texts
        print(observed_texts)
        
        // print("Observed texts: ", observed_texts)
        
        add_observations_for_model(observed_texts: observed_texts)
        add_observations_for_company(observed_texts: observed_texts)
    }
    
    func get_top_mask_or_company() -> (Mask?, Company?) {
        
        print_top_mask_by_model_and_company()
        print_top_company()
        
        // Find the top mask purely by both the mask factor and the company factor
        let top = model_candidates.max(by: { (m1, m2) -> Bool in
            return m1.value.get_weight() < m2.value.get_weight()
        })
        
        // Check sufficient weight
        if let top = top, top.value.get_weight() > 0.4 {
            return (top.key, nil)
        } else {
            
            // Possibly good enough guess for company
            // Find top company
            let top_company = company_candidates.max { (c1, c2) -> Bool in
                return c1.value.get_weight() < c2.value.get_weight()
            }
            print("Top company: ", top_company?.key)
            
            if let top_company = top_company, top_company.value.get_weight() > 0.5 {
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
        
        print("Top 3 mask candidates by model + company:")
        var i = 0
        for (mask, rhs) in ms {
            print(mask.company, ": ", mask.model, " ~ ", mask.search_model, ": weight: ", rhs.get_weight())
            
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
                
                // Find the company!
                guard let ret = find_company_for_mask(mask: mask) else {
                    print("Could not find company, company candidate for mask observation: ", mask)
                    continue
                }
                
                model_candidates[mask] = ModelCandidate(model_candidate: MyCandidate(), company: ret.0, company_candidate: ret.1)
            }
        }
        
        // Add observations for all candidates
        for (mask_candidate, rhs) in model_candidates {
            if let weight = weights[mask_candidate] {
                // There exists an observation for this candidate
                rhs.model_candidate.add_observation(weight)
            } else {
                // No observation right now
                // "Expire" old observations i.e. get smaller = less important
                rhs.model_candidate.expire_observations_if_exist()
            }
        }
    }

    private mutating func find_company_for_mask(mask : Mask) -> (Company, MyCandidate)? {
        
        // First try candidates
        var ret : (Company, MyCandidate)? = nil
        let cf = company_candidates.filter({ (c) -> Bool in
            return c.key.name == mask.company
        })
        if cf.count == 1 {
            let company = cf.first!.key
            let company_candidate = cf.first!.value
            ret = (company, company_candidate)
        } else {
            
            // Need to create a candidate company
            // Find the company
            let cf2 = companies.filter { (c) -> Bool in
                return c.name == mask.company
            }
            if cf2.count == 1 {
                let company = cf2.first!
                let company_candidate = MyCandidate()
                ret = (company, company_candidate)

                // Add to the companies dict
                company_candidates[company] = company_candidate
                
            } else {
                // Uh oh!
                print("Could not find company corresponding to mask: ", mask)
            }
        }
        
        return ret
    }
    
    private mutating func add_observations_for_company(observed_texts : [String]) {
        
        // Collect weights
        var weights : [Company : Float] = [:]
        for observed_text in observed_texts {
            
            let companies_filtered = companies.filter({ (company) -> Bool in
                return company.search_name.contains(observed_text)
            })
            
            for company in companies_filtered {
                // Min weight = 0
                // Max weight = 1 => all of the name was found, i.e. the two match exactly
                // Square to skew the distribution
                let weight = pow(Float(observed_text.count) / Float(company.search_name.count), 2)
                if weights[company] == nil {
                    weights[company] = 0.0
                }
                weights[company]! += weight
            }
        }
        
        // Ensure all observed masks have a candidate
        for (company, _) in weights {
            if company_candidates[company] == nil {
                company_candidates[company] = MyCandidate()
            }
        }
        
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
